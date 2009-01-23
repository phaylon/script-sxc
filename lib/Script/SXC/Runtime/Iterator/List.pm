package Script::SXC::Runtime::Iterator::List;
use Moose;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose    qw( ArrayRef Int Maybe );

use namespace::clean -except => 'meta';
use overload
    '@{}'    => 'to_list',
    fallback => 1;

has list => (
    metaclass   => 'Collection::Array',
    is          => 'ro',
    isa         => ArrayRef,
    required    => 1,
    provides    => {
        'get'       => 'get_value_at_index',
        'count'     => 'count_values',
    },
);

method to_list { $self->list }

method last_index { $self->count_values - 1 }

has current => (
    is          => 'rw',
    isa         => Maybe[Int],
    clearer     => 'clear_current',
);

method clear { $self->clear_current }

method current_value { $self->get_value_at_index($self->current) }

method next_step {
    
    my $current = $self->current;
    if (defined $current and $current >= $self->last_index) {
        return $self->end;
    }

    my $next;
    if (not defined $current) {
        $self->end_of_stream(0);
        $next = 0;
    }
    else {
        $next = $current + 1;
    }

    $self->current($next);
    return $self->get_value_at_index($next);
}

with 'Script::SXC::Runtime::Iteration';

1;
