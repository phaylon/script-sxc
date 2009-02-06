package Script::SXC::Compiled::SyntaxRules::Transformer::Container;
use 5.010;
use Moose;
use Moose::Util             qw( get_all_attribute_values );
use MooseX::Types::Moose    qw( Object Str );
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Tree::List';

has container_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

method transform_to_tree (Object $transformer, Object $compiler, Object $env, Object $context, ArrayRef $coordinates) {

    # get all of our attributes
    my $attrs = get_all_attribute_values $self->meta, $self;

    # transform contents
    $attrs->{contents} = [ map { ($transformer->transform_to_tree($compiler, $env, $_, $context, $coordinates)) } @{ $self->contents }];

    # build container instance
    return $self->container_class->new(%$attrs);
}

with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';
with 'Script::SXC::Compiled::SyntaxRules::Transformer::Iteration';

1;
