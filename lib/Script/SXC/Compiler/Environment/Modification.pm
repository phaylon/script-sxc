package Script::SXC::Compiler::Environment::Modification;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object );

use namespace::clean -except => 'meta';

has variable => (
    is          => 'rw',
    isa         => 'Script::SXC::Compiler::Environment::Variable',
    required    => 1,
    handles     => {
        'render_variable' => 'render',
    },
);

has expression => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_expression' => 'render',
    },
);

method render {

    # setting the lexical var to the right value.
    # it's an expression, not a statement.
    return sprintf '(do { %s = %s })',
        $self->render_variable,
        $self->render_expression;
}

__PACKAGE__->meta->make_immutable;

1;
