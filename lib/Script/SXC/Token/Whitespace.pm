package Script::SXC::Token::Whitespace;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match_regex { 
    qr/\s+/ms;
};

method build_tokens ($value) {
    my $class = ref($self) || $self;

    # no transformation required
    return $class->new(value => $value);
};

1;
