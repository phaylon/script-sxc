package Script::SXC::Compiled::SyntaxRules::Rule;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( CodeRef Object );

use namespace::clean -except => 'meta';

has pattern => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

has transformer => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

1;
