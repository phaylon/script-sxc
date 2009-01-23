package Script::SXC::Compiled::Iteration;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Object );

use Script::SXC::Types qw( Method );
use Script::SXC::lazyload
    ['Script::SXC::Compiled::TypeCheck', 'CompiledTypeCheck'],
    'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

has compile_body => (
    is          => 'rw',
    isa         => Method,
    required    => 1,
);

has compiled_source => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

has source_item => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => [qw( source_information )],
);

method render {
    my $iterator_var = Variable->new_anonymous('iterator');

    return sprintf(
        '(do { require %s; my %s = %s(%s); %s })',
        'Script::SXC::Runtime',
        $iterator_var->render,
        'Script::SXC::Runtime::make_iterator',
        CompiledTypeCheck->new(
            expression  => $self->compiled_source,
            type        => 'list',
            message     => 'Iteration source must be list or range',
            source_item => $self->source_item,
        )->render,
        $self->compile_body->($self, $iterator_var),
    );
}

1;
