package Script::SXC::Library::Item::Procedure;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( CodeRef HashRef Str Method Str Bool ArrayRef );

use Data::Dump qw( pp );
use B::Deparse;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value',         'CompiledValue'],
    ['Script::SXC::Compiled::Application',   'CompiledApply'],
    ['Script::SXC::Tree::List',              'ListClass'    ],
    ['Script::SXC::Tree::Builtin',           'BuiltinClass' ],
    'Script::SXC::Library::Item::Procedure::Inlined',
    'Script::SXC::Compiler::Environment::Variable::Internal';

use namespace::clean -except => 'meta';

with 'Script::SXC::TypeHinting';
with 'Script::SXC::Library::Item::Inlining';
with 'Script::SXC::CompileToSelf';
with 'Script::SXC::ProvidesSetter';
with 'Script::SXC::Library::Item::Location';

method build_default_typehint { 'code' }

has firstclass => (
    is          => 'ro',
    isa         => Method,
    required    => 1,
);

has firstclass_inlining => (
    is          => 'rw',
    isa         => Bool,
    default     => 0,
);

has runtime_req => (
    is          => 'rw',
    isa         => ArrayRef,
    default     => sub { [] },
);

has runtime_lex => (
    is          => 'rw',
    isa         => HashRef,
    default     => sub { {} },
);

method accept_compiler (Object $compiler!, ScalarRef :$item_ref) {

    if ($compiler->inline_firstclass_procedures and $self->firstclass_inlining) {

        return Inlined->new(%$self, compiler => $compiler);
    }
    else {

        $compiler->add_required_package($self->library);
        return undef;
    }
}

with 'Script::SXC::Library::Item::AcceptCompiler';

method render {

    # can we make a direct inline?
#    if ($self->inliner) {
#        return sprintf '(sub {( %s )})', $self->inliner
#    }

    # TODO register library dependency in compiler
    
    return sprintf('(%s->get(%s)->firstclass)', $self->library, pp($self->name)),
};

__PACKAGE__->meta->make_immutable;

1;
