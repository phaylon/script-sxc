package Script::SXC::Library::Item::Procedure;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( CodeRef HashRef Str Method Str );

use Data::Dump qw( pp );

use aliased 'Script::SXC::Compiled::Value',         'CompiledValue';
use aliased 'Script::SXC::Compiled::Application',   'CompiledApply';
use aliased 'Script::SXC::Tree::List',              'ListClass';
use aliased 'Script::SXC::Tree::Builtin',           'BuiltinClass';

use aliased 'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

with 'Script::SXC::TypeHinting';
with 'Script::SXC::Library::Item::Inlining';

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

method accept_compiler (Object $compiler!, Object $env!, Object $symbol!) {

    my $argvar = Variable->new_anonymous('fc_inline');

#    return ListClass->new(contents => [
#        BuiltinClass->new(value => 'lambda'),
#        $argvar,
#        ListClass->new(contents => [
#            BuiltinClass->new(value => 'apply'),
#            $symbol,
#            $argvar,
#        ]),
#    ])->compile($compiler, $env);

#    return CompiledValue->new(content => sprintf '(sub { my %s = [@_]; (%s) })', 
#        CompiledApply->new(
#            invocant    => $self,
#            arguments   => 
#        ),
#    );
}

method can_accept_compiler { ! ! $self->inliner }

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
