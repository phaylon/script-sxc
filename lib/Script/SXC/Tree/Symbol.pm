package Script::SXC::Tree::Symbol;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use Data::Dump qw( pp );

use Script::SXC::lazyload
    ['Script::SXC::Runtime::Symbol', 'RuntimeSymbol'],
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

method compile (Object $compiler, Object $env, Bool :$fc_inline_optimise?) {
    $fc_inline_optimise //= 1;

    # find var in environment
    my $item = $env->find_variable($self);

    # wants a compiler
    if ($item->can('does') and $item->does('Script::SXC::Library::Item::AcceptCompiler')) {
        $item->accept_compiler($compiler, $env);
    }

    # return uncompiled item
    return $item;
}

method quoted (Object $compiler!, Object $env!) {

    # build compiled value
    return CompiledValue->new(content => sprintf '%s->new(value => %s)', RuntimeSymbol, pp $self->value);
};

with 'Script::SXC::Tree::Quotability';

__PACKAGE__->meta->make_immutable;

1;
