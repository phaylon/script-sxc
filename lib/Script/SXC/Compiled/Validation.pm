package Script::SXC::Compiled::Validation;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str Object );

use Data::Dump qw( pp );

use Script::SXC::lazyload
    'Script::SXC::Exception::ArgumentError';

use namespace::clean -except => 'meta';

requires qw( render_test render_message );

has exception_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    default     => ArgumentError,
);

has exception_type => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    builder     => 'build_default_exception_type',
);

has expression => (
    is          => 'rw',
    isa         => Object,
    handles     => {
        'render_expression' => 'render',
    },
);

has symbol => (
    is          => 'rw',
    isa         => Object,
    handles     => {
        'parameter_name' => 'value',
    },
);

method render {
    return sprintf('(do { %s or %s->throw_to_caller(type => %s, message => %s) })',
        $self->render_test,
        $self->exception_class,
        pp($self->exception_type),
        pp($self->render_message),
    );
}

1;
