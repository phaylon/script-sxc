package Script::SXC::Token::Boolean;
use Moose;

use Script::SXC::Types qw( Bool );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Bool);

method match_regex { 
    qr/
        \#
        (?: 
            true  | t
          | false | f
          | yes   | y
          | no    | n
        )
    /xi
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # boolean values are parsed lowercase
    $value = lc $value;

    # true or false?
    $value = $value =~ /^#[ty]/ ? 1 : undef;

    # new token
    return $class->new(value => $value);
};

1;
