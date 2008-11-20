package Script::SXC::Compiler::Environment::Definition;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object );

use namespace::clean -except => 'meta';

has variable => (
    is              => 'ro',
    isa             => 'Script::SXC::Compiler::Environment::Variable',
    required        => 1,
    handles         => {
        'render_variable'   => 'render',
        'variable_typehint' => 'typehint',
    },
);

has expression => (
    is              => 'rw',
    isa             => Object,
    handles         => {
        'render_expression'   => 'render',
        'expression_typehint' => 'typehint',
        'expression_does'     => 'does',
    },
);

method render {

    # render definition statement
    return sprintf 'my %s; %s = %s', 
        $self->render_variable,
        $self->render_variable,
        $self->render_expression;
}

__PACKAGE__->meta->make_immutable;

1;
