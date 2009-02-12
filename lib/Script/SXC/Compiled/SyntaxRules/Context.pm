package Script::SXC::Compiled::SyntaxRules::Context;
use 5.010;
use Moose;
use MooseX::Types::Moose        qw( Object Str HashRef ArrayRef );
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Data::Dump qw( pp );

use signatures;
use namespace::clean -except => 'meta';

has _capture_store => (
    metaclass   => 'Collection::Hash',
    is          => 'ro',
    isa         => HashRef,
    required    => 1,
    default     => sub { {} },
    provides    => {
        'exists'    => 'has_capture_store_for',
        'get'       => 'get_capture_store_for',
        'set'       => 'set_capture_store_for',
    },
);

has _iteration_value_counts => (
    metaclass   => 'Collection::Array',
    is          => 'ro',
    isa         => ArrayRef,
    required    => 1,
    default     => sub { [] },
    provides    => {
        'get'       => 'get_iteration_count_on_level',
        'set'       => 'set_iteration_count_on_level',
    },
);

has rule => (
    is          => 'ro',
    isa         => Object,
    required    => 1,
);

method build_tree (Object $compiler, Object $env) {
    my $tree = $self->rule->build_tree($compiler, $env, $self);
    #pp $self->_iteration_value_counts;
    #pp $self->_capture_store;
    #pp $tree;
    return $tree;
}

method compile_tree (Object $compiler, Object $env) {
    my $tree = $self->build_tree($compiler, $env)->compile($compiler, $env);
    return $tree;
}

method update_iteration_count (ArrayRef $coordinates) {

    # can't update if there is no iteration on this
    return unless @$coordinates;

    # calculate current count
    my $level   = @$coordinates;
    my $current = $self->get_iteration_count_on_level($level) // 0;
    my $new     = $coordinates->[-1] + 1;

    # update count if new count is higher
    $self->set_iteration_count_on_level($level, $new > $current ? $new : $current);
    return 1;
}

method set_capture_value (Str $name, ArrayRef $coordinates, $value) {

    # we have deep coordinates
    if (@$coordinates) {

        my @coord = @$coordinates;
        my $store = $self->get_capture_store_for($name);

        # initialise store if we don't have one for this yet
        unless ($store) {
            $self->set_capture_store_for($name, $store = []);
        }

        # walk the structure up to one before the last index
        my $last  = pop @coord;
        for my $index (@coord) {
            $store = $store->[ $index ] //= [];
        }

        # set the value on that structure's index
        $store->[ $last ] = $value;

        # remember how many values we had on this level
        $self->update_iteration_count($coordinates);
    }

    # no coordinates, no value collection
    else {
        $self->set_capture_store_for($name, $value);
    }

    return 1;
}

method get_capture_value (Str $name, ArrayRef $coordinates) {

    # deep level retrieval
    if (@$coordinates) {

        # walk structure for every index in the coordinates
        my $store = $self->get_capture_store_for($name);
        for my $index (@$coordinates) {
            $store = $store->[ $index ];
        }

        # return the value
        return $store;
    }

    # no coordinates, simple value
    else {
        return $self->get_capture_store_for($name);
    }
}

__PACKAGE__->meta->make_immutable;

1;
