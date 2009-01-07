package Script::SXC::Compiled::TypeCheck;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object Str );

use Data::Dump qw( pp );

use Script::SXC::lazyload
    'Script::SXC::Exception::ArgumentError',
    'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

with 'Script::SXC::CompileToSelf';

has expression => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_expression'     => 'render',
        'expression_typehint'   => 'typehint',
        'expression_isa'        => 'isa',
    },
);

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
    default     => 'argument_error',
);

has message => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has source_item => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => [qw( source_information )],
);

my %TypeTemplate = (
    'string'    => '(not(Scalar::Util::blessed(%s)) and defined(%s))',
    'object'    => 'Scalar::Util::blessed(%s)',
    'list'      => '(ref(%s) and ref(%s) eq q(ARRAY))',
    'hash'      => '(ref(%s) and ref(%s) eq q(HASH))',
    'code'      => '(ref(%s) and ref(%s) eq q(CODE))',
    'regex'     => '(ref(%s) and ref(%s) eq q(Regexp))',
    'symbol'    => '(Scalar::Util::blessed(%s) and %s->isa(q(Script::SXC::Runtime::Symbol)))',
    'keyword'   => '(Scalar::Util::blessed(%s) and %s->isa(q(Script::SXC::Runtime::Keyword)))',
);

has type => (
    is          => 'rw',
    isa         => enum(undef, keys %TypeTemplate),
    required    => 1,
);

method render {

#    warn "TYPECHECK " . $self->expression . "\n";

    return $self->render_expression
        if not($self->expression_isa('Script::SXC::Compiler::Environment::Variable::Outer'))
            and $self->expression_typehint 
            and $self->expression_typehint eq $self->type;

#    warn "NO TYPEMATCH\n";

    my $anon          = Variable->new_anonymous('typecheck');
    my $anon_rendered = $anon->render;

    return sprintf('(do { my %s = %s; unless(%s) { %s->throw_to_caller(%s) } %s })',
        $anon_rendered,
        $self->render_expression,
        do { (my $template = $TypeTemplate{ $self->type }) =~ s/\%s/$anon_rendered/g; $template },
        $self->exception_class,
        pp(
            type    => $self->exception_type,
            message => $self->message,
            up      => 1,
            $self->source_information,
        ),
        $anon_rendered,
    );
}

1;
