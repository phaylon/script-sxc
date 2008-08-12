package Script::SXC::Reader::Stream;
use Moose;
use MooseX::AttributeHelpers;

use Data::Dump qw( dump );

use Script::SXC::Reader::Types qw( SourceObject Str TokenObject );

use aliased 'Script::SXC::Exception::ParseError';
use aliased 'Script::SXC::Reader::Source::String', 'StringSourceClass';

# token classes
use aliased 'Script::SXC::Token::Symbol',       'SymbolTokenClass';
use aliased 'Script::SXC::Token::Whitespace',   'WhitespaceTokenClass';
use aliased 'Script::SXC::Token::Number',       'NumberTokenClass';
use aliased 'Script::SXC::Token::Keyword',      'KeywordTokenClass';
use aliased 'Script::SXC::Token::Character',    'CharacterTokenClass';
use aliased 'Script::SXC::Token::Boolean',      'BooleanTokenClass';
use aliased 'Script::SXC::Token::Comment',      'CommentTokenClass';
use aliased 'Script::SXC::Token::CellOpen',     'CellOpenTokenClass';
use aliased 'Script::SXC::Token::CellClose',    'CellCloseTokenClass';
use aliased 'Script::SXC::Token::Quote',        'QuoteTokenClass';
use aliased 'Script::SXC::Token::Unquote',      'UnquoteTokenClass';
use aliased 'Script::SXC::Token::Dot',          'DotTokenClass';
use aliased 'Script::SXC::Token::String',       'StringTokenClass';

use aliased 'Script::SXC::Token::Invalid::String',       'InvalidStringTokenClass';
use aliased 'Script::SXC::Token::Invalid::Number',       'InvalidNumberTokenClass';
use aliased 'Script::SXC::Token::Invalid::Keyword',      'InvalidKeywordTokenClass';
use aliased 'Script::SXC::Token::Invalid::Boolean',      'InvalidBooleanTokenClass';

use namespace::clean -except => 'meta';
use Method::Signatures;

has source => (
    is          => 'rw',
    isa         => SourceObject,
    coerce      => 1,
    required    => 1,
    handles     => {
        'next_source_line'      => 'next_line',
        'end_of_source_stream'  => 'end_of_stream',
        'source_line_number'    => 'line_number',
        'source_line_content'   => 'line_content',
        'source_description'    => 'source_description',
    },
);

after next_source_line => method () {

    $self->line_buffer($self->source_line_content);
};

has line_buffer => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    lazy        => 1,
    predicate   => 'has_line_buffer',
    default     => '',
);

has token_buffer => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => 'ArrayRef[' . TokenObject . ']',
    provides    => {
        'push'      => 'add_tokens_to_buffer',
        'unshift'   => 'remove_first_token_from_buffer',
        'count'     => 'buffered_tokens_count',
    },
    default     => sub { [] },
    lazy        => 1,
);

has token_classes => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    lazy        => 1,
    coerce      => 1,
    builder     => 'build_default_token_classes',
);

method build_default_token_classes {

    return [
        NumberTokenClass,
        InvalidNumberTokenClass,
        StringTokenClass,
        InvalidStringTokenClass,
        KeywordTokenClass,
        InvalidKeywordTokenClass,
        BooleanTokenClass,
        InvalidBooleanTokenClass,
        CharacterTokenClass,
        CommentTokenClass,
        QuoteTokenClass,
        UnquoteTokenClass,
        CellOpenTokenClass,
        CellCloseTokenClass,
        DotTokenClass,
        SymbolTokenClass,
        WhitespaceTokenClass,
    ];
};

method next_token {

    # return first token in buffer if exists
    if ($self->buffered_tokens_count) {
        return $self->pop_token_from_buffer;
    }

    # try to find content we can match against
  CONTENTRUN:
    while (1) {

        # are we at the general end?
        return undef 
            if $self->end_of_source_stream 
               and not length $self->line_buffer;

        # go to the next line if we reached the end of the current
        if (not length $self->line_buffer) {
            $self->next_source_line;
            next CONTENTRUN;
        }

        # we should have content
        last CONTENTRUN;
    }

    # try to find a matching token
  MATCHRUN:
    while (1) {

        # go through token classes
      TOKENCLASS:
        for my $token_class (@{ $self->token_classes }) {

            # skip to next class if we don't have any matches
            my $tokens = $token_class->match($self)
                or next TOKENCLASS;

            # don't bother with the buffer if we only got one token
            return $tokens->[0] if @$tokens == 1;

            # try another round if we got no tokens
            next MATCHRUN if @$tokens == 0;

            # go through buffer if more than one token was returned
            $self->add_tokens_to_buffer(@$tokens);
            return $self->remove_first_token_from_buffer;
        }

        # we didn't know what to do with the rest of the content
        ParseError->throw(
            type                => 'cannot_parse',
            message             => sprintf('Unable to parse: ' . $self->line_buffer),
            line_number         => $self->source_line_number,
            source_description  => $self->source_description,
        );
    }
};

method all {
    my @tokens;

    # grab all tokens until the end
    while (my $token = $self->next_token) {
        push @tokens, $token;
    }

    # return either all or just the first token
    return wantarray ? @tokens : shift @tokens;
};

1;
