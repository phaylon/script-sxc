package Script::SXC::Token::CellOpen;
use Moose;

use Script::SXC::Types qw( Str );

use aliased 'Script::SXC::Exception::ParseError';
use aliased 'Script::SXC::Exception::MissingClose';
use aliased 'Script::SXC::Tree::List', 'ListClass';
use aliased 'Script::SXC::Tree::Hash', 'HashClass';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

my %MatchSet = qw/ ( ) [ ] { } /;

my %ListClass = (
    ')' => ListClass,
    ']' => ListClass,
    '}' => HashClass,
);

method match_regex {
    [qw/ ( [ { /]
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

method transform ($stream) {
    my @items;

    # walk through stream until we find an end
    while (my $token = $stream->next_token) {

        # finish off if we got a close
        if ($token->isa('Script::SXC::Token::CellClose')) {

            # a non-matching closing parens is a parse error
            ParseError->throw(
                type                => 'parenthesis_mismatch',
                message             => sprintf(q(Expected '%s' closing parenthesis but found '%s'),
                                        $MatchSet{ $self->value }, $token->value),
                $self->source_information,
            ) unless $token->value eq $MatchSet{ $self->value };

            # return the tree with the items
            return $ListClass{ $token->value }->new_from_token(
                $self,
                contents => \@items,
            );
        }

        # any other item gets transformed and is stored
        push @items, $token->transform($stream);
    }

    # if we reach this point, a parens is missing
    MissingClose->throw(
        type                => 'unexpected_end',
        message             => sprintf(q(Unexpected end of input, missing a '%s' closing parenthesis),
                                $MatchSet{ $self->value }),
        $self->source_information,
    );
};

__PACKAGE__->meta->make_immutable;

1;
