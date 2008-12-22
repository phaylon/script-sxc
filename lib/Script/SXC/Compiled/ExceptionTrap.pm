package Script::SXC::Compiled::ExceptionTrap;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object );

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable';

use Data::Dump qw( pp );

use constant LocalizedException => 'Script::SXC::Exception::Localized';

use namespace::clean -except => 'meta';

with 'Script::SXC::SourcePosition';

has expression => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_expression' => 'render_expression',
        'typehint'          => 'typehint',
        'type_might_be'     => 'type_might_be',
    },
);

method maybe_surround ($class: Object $expr!, Object $compiler!) {
    return $expr
        unless $compiler->localize_exceptions;
    $compiler->add_required_package('Scalar::Util', LocalizedException);
    return $class->new(expression  => $expr);
}

method render {
    my $result    = Variable->new_anonymous('exception_trap_result');
    my $exception = Variable->new_anonymous('exception');
    return sprintf(
        '(do { local $@; my %s = eval { %s }; %s; %s })',
        $result->render,
        $self->render_expression,
        sprintf(
            'if (%s) { %s }',
            sprintf('my %s = $@', $exception->render),
            sprintf(
                'if (not blessed(%s) or not scalar(grep { %s->isa($_) } (%s))) { %s }',
                $exception->render,
                $exception->render,
                join(', ', map { pp $_ } qw( Script::SXC::Exception )),
                sprintf(
                    '%s->throw(message => join("", %s), %s)',
                    LocalizedException,
                    $exception->render,
                    pp( type    => 'localized_external_exception',
                        $self->source_information,
                    ),
                ),
            ),
        ),
    );
}

1;
