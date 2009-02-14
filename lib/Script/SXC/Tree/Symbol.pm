package Script::SXC::Tree::Symbol;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use Scalar::Util qw( blessed );
use Data::Dump   qw( pp );

use Script::SXC::lazyload
    ['Script::SXC::Runtime::Symbol', 'RuntimeSymbol'],
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use CLASS;
use namespace::clean -except => 'meta';
use overload
    'eq'     => 'is_equal',
    fallback => 1;

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

method is_equal ($item, $is_reversed) {

    return undef
        unless defined $item;

    return $item->value eq $self->value
        if blessed($item) and $item->isa(CLASS);

    return $item eq $self->value;
}

method find_associated_item ($compiler, $env) {
    return $env->find_variable($self);
}

method compile (Object $compiler, Object $env, Bool :$fc_inline_optimise?) {
    $fc_inline_optimise //= 1;

    # find var in environment
    my $item = $self->find_associated_item($compiler, $env);

    # wants a compiler
    if ($item->does('Script::SXC::Library::Item::AcceptCompiler')) {
        my $replacement = $item->accept_compiler($compiler, $env, item_ref => \$item);
        $item = $replacement
            if defined $replacement;
    }

    # return uncompiled item
    return $item;
}

method quoted (Object $compiler!, Object $env!) {
    $compiler->add_required_package(RuntimeSymbol);

    # build compiled value
    return CompiledValue->new(content => sprintf '%s->new(value => %s)', RuntimeSymbol, pp $self->value);
};

with 'Script::SXC::Tree::Quotability';

__PACKAGE__->meta->make_immutable;

1;
