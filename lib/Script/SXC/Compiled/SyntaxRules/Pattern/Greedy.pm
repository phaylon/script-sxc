package Script::SXC::Compiled::SyntaxRules::Pattern::Greedy;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Bool Int );

use namespace::clean -except => 'meta';

has is_greedy => (
    is          => 'rw',
    isa         => Bool,
    default     => 0,
);

has greed_level => (
    is          => 'rw',
    isa         => Int,
    default     => 0,
);

has allow_greedy => (
    is          => 'rw',
    isa         => Bool,
    default     => 1,
);

1;
