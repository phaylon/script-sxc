package Script::SXC::Runtime::Iterator::Range;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( CodeRef Any Str Bool );

use namespace::clean -except => 'meta';
use overload
    '@{}'    => 'to_list',
    fallback => 1;

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

has current => (
    is          => 'rw',
    clearer     => 'clear_current',
);

has empty_stream => (
    is          => 'ro',
    isa         => Bool,
);

has range_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    handles     => {
        new_range_object => 'new',
    },
);

method range_from_here {
    return $self->new_range_object(
        start_at        => $self->current,
        stop_at         => $self->stop_at,
        stepper         => $self->stepper,
        empty_stream    => ($self->end_of_stream ? 1 : $self->empty_stream),
    );
}

method clear { $self->clear_current }

method current_value { $self->current }

method next_step {

    return $self->end
        if $self->empty_stream;

    my $current = $self->current;
    return $self->end
        if defined $current and $current >= $self->stop_at;

    my $next;
    if (not defined $current) {
        $self->end_of_stream(0);
        $next = $self->start_at;
    }
    else {
        $next = $self->stepper->($current);
        return $self->end
            if not defined $next or $next > $self->stop_at;
    }

    $self->current($next);
    return $next;
}

with 'Script::SXC::Runtime::Iteration';

__PACKAGE__->meta->make_immutable;

1;
