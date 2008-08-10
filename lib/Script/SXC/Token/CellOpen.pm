package Script::SXC::Token::CellOpen;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match_regex {
    [qw/ ( [ /]
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

1;
