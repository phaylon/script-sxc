package Script::SXC::ProvidesSetter;
use Moose::Role;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

has setter => (
    is          => 'rw',
);

method can_build_setter { $self->setter }

method build_setter (Object $compiler!, Object $env!, ArrayRef $access_args!, Object $expr!, Object $symbol) {
    return $self->setter->($compiler, $env, $access_args, $expr, $symbol);
}

1;
