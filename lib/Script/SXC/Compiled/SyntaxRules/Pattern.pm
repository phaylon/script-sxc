package Script::SXC::Compiled::SyntaxRules::Pattern;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( HashRef ArrayRef Object Int );

use constant SequenceMatchingRole   => 'Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching';
use constant ListClass              => 'Script::SXC::Tree::List';

use Data::Dump qw( pp );

use namespace::clean -except => 'meta';

has captures => (
    metaclass       => 'Collection::Array',
    is              => 'rw',
    isa             => ArrayRef[Object],
    required        => 1,
    default         => sub { [] },
    provides        => {
        'count'         => 'capture_count',
        'get'           => 'get_capture',
        'push'          => 'add_capture',
    },
);

has capture_objects => (
    metaclass       => 'Collection::Hash',
    is              => 'rw',
    isa             => HashRef[Object],
    required        => 1,
    default         => sub { {} },
    provides        => {
        'exists'        => 'has_capture',
        'set'           => 'set_capture_object',
        'get'           => 'get_capture_object',
    },
);

has greedy_max_depth => (
    is              => 'rw',
    isa             => Int,
    required        => 1,
    default         => 0,
);

method update_greedy_max_depth (Int $new) {

    # only set the depth if it is larger than the current value
    $self->greedy_max_depth($new) and return 1
        if $new > $self->greedy_max_depth;

    return undef;
}

method new_from_uncompiled (Str $class: Object $compiler, Object $env, ArrayRef $items, Object $sr) {

    # create a new pattern and transform its items
    my $self = $class->new;
    $self->items($class->transform_sequence($compiler, $env, $items, $sr, $self, 0));

    # return the new instance
    return $self;
}

with SequenceMatchingRole;
with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

has '+container_class'   => (default => ListClass);
has '+alternate_reftype' => (default => 'ARRAY');

__PACKAGE__->meta->make_immutable;

1;
