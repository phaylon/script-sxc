package Script::SXC::Compiled::Values;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object );

use namespace::clean -except => 'meta';

has expression => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_expression' => 'render',
    },
);

method render {
    # TODO - make sure its a list (compiletime & runtime)
    #      - take typehints into account

    # dereference the list expression
    return sprintf '(@{( %s )})', $self->render_expression;
}

__PACKAGE__->meta->make_immutable;

1;
