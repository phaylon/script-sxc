package Script::SXC::Compiled::SyntaxRules::Pattern;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( ArrayRef Object );

use constant SequenceMatchingRole   => 'Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching';
use constant ListClass              => 'Script::SXC::Tree::List';

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

method new_from_uncompiled (Str $class: Object $compiler, Object $env, ArrayRef $items, Object $sr) {

    my $self = $class->new;
    $self->items([ map { $class->transform($compiler, $env, $_, $sr, $self) } @$items ]);

    return $self;
}

with SequenceMatchingRole;
with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

has '+container_class'   => (default => ListClass);
has '+alternate_reftype' => (default => 'ARRAY');

1;
