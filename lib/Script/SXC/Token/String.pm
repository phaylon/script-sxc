package Script::SXC::Token::String;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

extends 'Script::SXC::Token::Symbol';

has '+value' => (isa => Str);

method match_regex {
    qr/" .* (?<! \\ ) "/xsm;
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

method transform {
    die "TODO\n";
};

1;
