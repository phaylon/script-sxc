package Script::SXC::Compiled::SyntaxRules::Transformer;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Object HashRef );

use constant ListClass   => 'Script::SXC::Tree::List';
use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use Script::SXC::lazyload
    [ListClass,     'ListItem'],
    [SymbolClass,   'SymbolItem'];

use namespace::clean -except => 'meta';

has template => (
    is          => 'rw',
    isa         => Object,
);

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern) {

    my $self = $class->new;
    $self->template($self->build_template($compiler, $env, $expr, $sr, $pattern));
    return $self;
}

method build_template (Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern) {

    if ($expr->isa(ListClass)) {
        return $expr->meta->clone_object($expr, content => [
            map { $self->build_template($compiler, $env, $_, $sr, $pattern) } @{ $expr->contents }
        ]);
    }
    elsif ($expr->isa(SymbolClass)) {
        return $expr;
    }
}

1;
