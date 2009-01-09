package Script::SXC::Compiled::Conditional;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable';

use Script::SXC::Types qw( Object Str );

use namespace::clean -except => 'meta';

has condition => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_condition'  => 'render',
    },
);

has consequence => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_consequence'  => 'render',
    },
);

has alternative => (
    is          => 'rw',
    isa         => Object,
    predicate   => 'has_alternative',
    handles     => {
        'render_alternative'  => 'render',
    },
);

has mode => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    default     => 'if',
);

my %ModeTemplate = (
    'if'     => 'scalar(%s)',
    'unless' => 'not(scalar(%s))',
);

method render {

    # build conditional structure
    my $expr = sprintf(
        '( %s ? scalar(%s) : scalar(%s))',
        sprintf($ModeTemplate{ $self->mode }, $self->render_condition),
        $self->consequence->render,
      ( $self->has_alternative ? $self->alternative->render : 'undef' ),
    );

    # rendering finished
    return $expr;
};

__PACKAGE__->meta->make_immutable;

1;
