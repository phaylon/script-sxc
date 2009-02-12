package Script::SXC::Compiled::Validation::Count;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Int );

use Carp qw( croak );

use namespace::clean -except => 'meta';

has min => (
    is          => 'rw',
    isa         => Int,
    predicate   => 'has_min',
);

has max => (
    is          => 'rw',
    isa         => Int,
    predicate   => 'has_max',
);

method render_test {
      $self->has_min ? sprintf('(@_ >= %d)', $self->min) 
    : $self->has_max ? sprintf('(@_ <= %d)', $self->max)
    : croak "Either min or max are required";
}

method render_message {
      $self->has_min ? sprintf('Missing arguments: Expected at least %d arguments',      $self->min)
    : $self->has_max ? sprintf('Too many arguments: Expected no more than %d arguments', $self->max)
    : croak "Either min or max are required";
}

method build_default_exception_type { 'invalid_argument_count' }

with 'Script::SXC::Compiled::Validation';

__PACKAGE__->meta->make_immutable;

1;
