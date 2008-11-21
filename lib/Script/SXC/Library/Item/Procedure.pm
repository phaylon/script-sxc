package Script::SXC::Library::Item::Procedure;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( CodeRef HashRef Str Method Str );

use Data::Dump qw( pp );

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

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

method render {

    # TODO register library dependency in compiler

    return sprintf('(%s->get(%s)->firstclass)', $self->library, pp($self->name)),
};

__PACKAGE__->meta->make_immutable;

1;
