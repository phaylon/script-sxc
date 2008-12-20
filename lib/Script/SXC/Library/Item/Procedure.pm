package Script::SXC::Library::Item::Procedure;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( CodeRef HashRef Str Method Str );

use Data::Dump qw( pp );

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value',         'CompiledValue'],
    ['Script::SXC::Compiled::Application',   'CompiledApply'],
    ['Script::SXC::Tree::List',              'ListClass'    ],
    ['Script::SXC::Tree::Builtin',           'BuiltinClass' ],
    'Script::SXC::Compiler::Environment::Variable::Internal';

use namespace::clean -except => 'meta';

with 'Script::SXC::TypeHinting';
with 'Script::SXC::Library::Item::Inlining';
with 'Script::SXC::CompileToSelf';

method build_default_typehint { 'code' }

has firstclass => (
    is          => 'ro',
    isa         => Method,
    required    => 1,
);

has name => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

has library => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

method accept_compiler (Object $compiler!) {
    $compiler->add_required_package($self->library);
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
