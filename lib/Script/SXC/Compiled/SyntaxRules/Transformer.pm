package Script::SXC::Compiled::SyntaxRules::Transformer;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Object HashRef );

use constant InsertCapturedClass => 'Script::SXC::Compiled::SyntaxRules::Transformer::InsertCaptured';
use constant LibraryItemClass    => 'Script::SXC::Compiled::SyntaxRules::Transformer::LibraryItem';
use constant GeneratedClass      => 'Script::SXC::Compiled::SyntaxRules::Transformer::Generated';
use constant TransformationRole  => 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';
use constant ListClass           => 'Script::SXC::Tree::List';
use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant ContainerRole       => 'Script::SXC::Tree::Container';
use constant LocationRole        => 'Script::SXC::Library::Item::Location';
use constant VariableClass       => 'Script::SXC::Compiler::Environment::Variable';

use Script::SXC::lazyload
    [GeneratedClass,        'Generated'],
    [VariableClass,         'Variable'],
    [InsertCapturedClass,   'InsertCaptured'],
    [LibraryItemClass,      'LibraryItem'],
    [ListClass,             'ListItem'],
    [SymbolClass,           'SymbolItem'];

use List::MoreUtils qw( any );
use Data::Dump      qw( pp );

use namespace::clean -except => 'meta';

has template => (
    is          => 'rw',
    isa         => Object,
);

has anon_variables => (
    metaclass   => 'Collection::Hash',
    is          => 'rw',
    isa         => HashRef[Object],
    required    => 1,
    default     => sub { {} },
    provides    => {
        'keys'      => 'anon_variable_names',
        'values'    => 'anon_variable_objects',
        'get'       => 'get_anon_variable',
        'set'       => 'set_anon_variable',
        'exists'    => 'has_anon_variable',
    },
);

method build_tree (Object $compiler, Object $env, HashRef $captures) {

    my $tree = $self->transform_to_tree($compiler, $env, $self->template, $captures);
#    pp $tree;
    return $tree;
}

method transform_to_tree (Object $compiler, Object $env, Object $item, HashRef $captures) {

    if ($item->does(ContainerRole)) {

        return $item->meta->clone_object($item, contents => [
            map { $self->transform_to_tree($compiler, $env, $_, $captures) } @{ $item->contents }
        ]);
    }

    elsif ($item->does(TransformationRole)) {

        return $item->transform_to_tree($self, $compiler, $env, $captures);
    }

    else {

        return $item->meta->clone_object($item);
    }
}

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern) {

    my $self = $class->new;
    $self->template($self->build_template($compiler, $env, $expr, $sr, $pattern));
    return $self;
}

method build_template (Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern) {

    if ($expr->does(ContainerRole)) {

        return $expr->meta->clone_object($expr, contents => [
            map { $self->build_template($compiler, $env, $_, $sr, $pattern) } @{ $expr->contents }
        ]);
    }
    elsif ($expr->isa(SymbolClass)) {

        if (any { $expr eq $_ } @{ $pattern->captures }) {

            return InsertCaptured->new(name => $expr->value);
        }
        elsif ($expr eq '.') {

            return $expr;
        }
        else {

            unless ($env->find_env_for_variable($expr->value)) {

                if ($self->has_anon_variable($expr->value)) {

                    return $self->get_anon_variable($expr->value);
                }
                else {

                    my $anon = Generated->new_from_symbol($expr);
                    #my $anon = Variable->new_anonymous('gensym_' . $expr->value);
                    $self->set_anon_variable($expr->value, $anon);
                    return $anon;
                }
            }

            my $compiled = $expr->compile($compiler, $env);

            if ($compiled->does(LocationRole)) {

                return LibraryItem->new($compiled->library_location);
            }
            elsif ($compiled->isa(VariableClass)) {

                return $compiled;
            }
        }
    }

    return $expr;
}

1;
