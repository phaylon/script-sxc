package Script::SXC::Compiled::Conditional;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable';

use Script::SXC::Types qw( Object );

use namespace::clean -except => 'meta';

has condition => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

has consequence => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

has alternative => (
    is          => 'rw',
    isa         => Object,
    predicate   => 'has_alternative',
);

method render {

    # used anonymouse vars
#    my $var_result = Variable->new_anonymous('if_result')->render;

    # build conditional structure
    my $expr = sprintf(
        '(scalar(%s) ? scalar(%s) : scalar(%s))',
        $self->condition->render,
        $self->consequence->render,
      ( $self->has_alternative ? $self->alternative->render : 'undef' ),
    );


#    my $expr = sprintf 'do { my %s; if (%s) { %s = %s } else { %s = %s } %s }',
#        $var_result,
#        $self->condition,
#        $var_result,
#        $self->consequence,
#        $var_result,
#       ($self->has_alternative ? $self->alternative : 'undef'),
#        $var_result;

    # rendering finished
    return $expr;
};

__PACKAGE__->meta->make_immutable;

1;
