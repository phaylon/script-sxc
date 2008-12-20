package Script::SXC::Token::CellClose;
use Moose;

use Script::SXC::Types qw( Str );

use Script::SXC::lazyload
    'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
use Method::Signatures;

my $CloseParens  = ')';
my $CloseSquare  = ']';
my $CloseBracket = '}';

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match_regex {
    [$CloseParens, $CloseSquare, $CloseBracket];
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

method transform {

    ParseError->throw(
        type                => 'unexpected_close',
        message             => sprintf('Unexpected closing parenthesis \'%s\' found', $self->value),
        line_number         => $self->line_number,
        source_description  => $self->source_description,
    );
};

__PACKAGE__->meta->make_immutable;

1;
