package Script::SXC::Compiled::Scope;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( ArrayRef Object );
use MooseX::AttributeHelpers;

use namespace::clean -except => 'meta';

has expressions => (
    metaclass       => 'Collection::Array',
    is              => 'rw',
    isa             => ArrayRef[Object],
    required        => 1,
    builder         => 'build_default_expressions',
    lazy            => 1,
    provides        => {
        'push'          => 'add_expression',
    },
);

has definitions => (
    is              => 'ro',
    isa             => ArrayRef[Object],
    required        => 1,
    default         => sub { [] },
);

method render {

    # build expression body
    my $body = $self->render_expression_body;

    # wrap body in scope frame
    my $wrapped = $self->wrap_in_scope_frame($body);

    # finished rendering
    return $wrapped;
}

method wrap_in_scope_frame (Str $body) {

    # base default is a simple 'do' block as wrapper
    return "do { $body }";
}

method render_expression_body {

    # render expressions and join by statement delimiter
    return join ';', map  { $_->render } $self->all_expressions;
}

method all_expressions {
    return @{ $self->definitions }, $self->build_post_definition_statements, @{ $self->expressions };
}

method build_post_definition_statements { return () }

method build_default_expressions () {

    # base default is the empty expression list
    return [];
}

__PACKAGE__->meta->make_immutable;

1;
