package Script::SXC::Compiled::Context;
use Moose;
use Moose::Util::TypeConstraints;
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

my %Template = (
    'scalar'    => 'scalar(%s)',
    'hash'      => '+{( %s )}',
    'list'      => '[( %s )]',
);

has type => (
    is          => 'rw',
    isa         => enum(undef, keys %Template),
    required    => 1,
    default     => 'scalar',
);

method render {
    return sprintf $Template{ $self->type }, $self->render_expression;
}

__PACKAGE__->meta->make_immutable;

1;
