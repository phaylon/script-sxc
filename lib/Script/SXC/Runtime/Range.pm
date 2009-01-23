package Script::SXC::Runtime::Range;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( CodeRef Any Bool );

use aliased 'Script::SXC::Runtime::Iterator::Range', 'RangeIterator';

use namespace::clean -except => 'meta';
use overload
    '@{}'    => 'to_list',
    fallback => 1;

extends 'Script::SXC::Runtime::Object';

my $StepperType = subtype __PACKAGE__ . '::StepperType', as CodeRef;
coerce $StepperType, from Any, via { return $_ if ref eq 'CODE'; my $step = $_; sub { $_[0] + $step } };

has stepper => (
    is          => 'rw',
    isa         => $StepperType,
    coerce      => 1,
    required    => 1,
);

has start_at => (
    is          => 'rw',
    required    => 1,
);

has stop_at => (
    is          => 'rw',
    required    => 1,
);

has empty_stream => (
    is          => 'ro',
    isa         => Bool,
);

method to_list { $self->to_iterator->to_list }

method to_iterator {
    return RangeIterator->new(
        stepper         => $self->stepper,
        start_at        => $self->start_at,
        stop_at         => $self->stop_at,
        range_class     => ref($self),
        empty_stream    => $self->empty_stream,
    );
}

1;
