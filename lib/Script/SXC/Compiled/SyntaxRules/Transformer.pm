package Script::SXC::Compiled::SyntaxRules::Transformer;
use 5.010;
use Moose;
use Moose::Util             qw( get_all_attribute_values );
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Object HashRef );

use constant InsertCapturedClass => 'Script::SXC::Compiled::SyntaxRules::Transformer::InsertCaptured';
use constant LibraryItemClass    => 'Script::SXC::Compiled::SyntaxRules::Transformer::LibraryItem';
use constant GeneratedClass      => 'Script::SXC::Compiled::SyntaxRules::Transformer::Generated';
use constant ContainerClass      => 'Script::SXC::Compiled::SyntaxRules::Transformer::Container';
use constant TransformationRole  => 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';
use constant IterationRole       => 'Script::SXC::Compiled::SyntaxRules::Transformer::Iteration';
use constant ListClass           => 'Script::SXC::Tree::List';
use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant ContainerRole       => 'Script::SXC::Tree::Container';
use constant LocationRole        => 'Script::SXC::Library::Item::Location';
use constant VariableClass       => 'Script::SXC::Compiler::Environment::Variable';

use Script::SXC::lazyload
    [GeneratedClass,        'Generated'],
    [VariableClass,         'Variable'],
    [InsertCapturedClass,   'InsertCaptured'],
    [ContainerClass,        'Container'],
    [LibraryItemClass,      'LibraryItem'],
    [ListClass,             'ListItem'],
    [SymbolClass,           'SymbolItem'];

use List::MoreUtils qw( any first_value );
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

method build_tree (Object $compiler, Object $env, Object $context) {

    my $tree = $self->transform_to_tree($compiler, $env, $self->template, $context, []);
    return $tree;
}

method transform_to_tree (Object $compiler, Object $env, Object $item, Object $context, ArrayRef $coordinates) {

    # this item can be transformed
    if ($item->does(TransformationRole)) {
        return $item->transform_to_tree($self, $compiler, $env, $context, $coordinates);
    }

    # clone everything we can't transform
    else {
        return $item->meta->clone_object($item);
    }
}

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern) {

    my $self = $class->new;
    $self->template($self->build_template($compiler, $env, $expr, $sr, $pattern, 0));
    return $self;
}

method build_container_template (Object $compiler, Object $env, Object $container, Object $sr, Object $pattern, Int $it_level) {

    my @contents = @{ $container->contents };
    my @templates;

    # turn all of the containers contents into templates
    while (my $item = shift @contents) {
        my $is_iterative;
        
        # make the pattern iterative if the next item is an ellipsis
        if (@contents and $contents[0]->isa(SymbolClass) and $contents[0] eq '...') {
            $is_iterative = shift @contents;

            # bark if the pattern didn't go that deep
            unless ($it_level < $pattern->greedy_max_depth) {
                $item->throw_parse_error(syntax_iteration_depth_mismatch => "syntax-rules pattern did not go deeper than $it_level level(s)");
            }
        }

        # build template of this subexpression
        my $template = $self->build_template($compiler, $env, $item, $sr, $pattern, ($is_iterative ? ($it_level + 1) : $it_level));

        # iterative templates
        if ($is_iterative) {

            # not everything can be used iteratively
            unless ($template->does(IterationRole)) {
                $container->throw_parse_error(
                    'invalid_syntax_ellipsis',
                    sprintf 'Invalid placement of syntax-rules ellipsis in template after %s', ref($item),
                );
            }

            # set iterative properties
            $template->is_iterative(1);
            $template->iteration_level($it_level + 1);
        }

        push @templates, $template;
    }

    # construct container object
    return Container->new(
        %{ get_all_attribute_values $container->meta, $container },
        contents        => \@templates,
        container_class => ref($container),
    );
}

method build_capture_template (Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern, Int $it_level) {
    return InsertCaptured->new(name => $expr->value);
}

method build_generated_template (Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern, Int $it_level) {

    # return already created placeholder if one exists
    return $self->get_anon_variable($expr->value)
        if $self->has_anon_variable($expr->value);

    # create a new generated placeholder
    my $gensym = Generated->new_from_symbol($expr);
    $self->set_anon_variable($expr->value, $gensym);

    # return generated symbol
    return $gensym;
}

method build_template (Object $compiler, Object $env, Object $expr, Object $sr, Object $pattern, Int $it_level) {

    # expression is a container of some kind
    if ($expr->does(ContainerRole)) {
        return $self->build_container_template($compiler, $env, $expr, $sr, $pattern, $it_level);
    }

    # expression is a symbol
    elsif ($expr->isa(SymbolClass)) {

        # if we reach an ellipsis with this, it is wrongly placed
        if ($expr eq '...') {
            $expr->throw_parse_error(invalid_syntax_ellipsis => "Invalid ellipsis placement in syntax-rules template");
        }

        # capture symbols are replaced with inserting placeholders
        if (my $capture = $pattern->get_capture_object($expr->value)) {
            return $self->build_capture_template($compiler, $env, $expr, $sr, $pattern, $it_level);
        }

        # dots are taken literally
        elsif ($expr eq '.') {
            return $expr;
        }

        # this is an unknown symbol that must be replaced
        elsif (not $env->find_env_for_variable($expr->value)) {
            return $self->build_generated_template($compiler, $env, $expr, $sr, $pattern, $it_level);
        }

        # resolve a known symbol
        my $compiled = $expr->compile($compiler, $env);

        # if this symbol comes from a library we have to put a placeholder in
        if ($compiled->does(LocationRole)) {
            return LibraryItem->new($compiled->library_location);
        }

        # variables can be passed through
        elsif ($compiled->isa(VariableClass)) {
            return $compiled;
        }
    }

    # everything else
    return $expr;
}

1;
