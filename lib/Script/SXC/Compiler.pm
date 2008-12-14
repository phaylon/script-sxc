package Script::SXC::Compiler;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Bool );

use aliased 'Script::SXC::Compiler::Environment::Top',  'TopEnvironmentClass';
use aliased 'Script::SXC::Compiled',                    'CompiledUnitClass';
use aliased 'Script::SXC::Compiled::Values',            'CompiledValues';
use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';

has top_environment => (
    is          => 'rw',
    isa         => TopEnvironmentClass,
    required    => 1,
    builder     => 'build_top_environment',
    lazy        => 1,
    clearer     => 'clear_top_environment',
);

has top_compiled_unit => (
    is          => 'rw',
    isa         => CompiledUnitClass,
    required    => 1,
    builder     => 'build_top_compiled_unit',
    lazy        => 1,
    clearer     => 'clear_top_compiled_unit',
    handles     => {
        'add_compiled_expression'   => 'add_expression',
    },
);

has optimize_tailcalls => (
    is          => 'rw',
    isa         => Bool,
    default     => 0,
);

has cleanup_environment => (
    is          => 'rw',
    isa         => Bool,
    default     => 1,
);

has force_firstclass_procedures => (
    is          => 'rw',
    isa         => Bool,
    default     => 0,
);

method compile_tree (Object $tree) {

    $self->clear_top_environment if $self->cleanup_environment;
    $self->clear_top_compiled_unit;

    $self->add_compiled_expression($self->compile_expression($_, $self->top_environment))
        for @{ $tree->contents };

    return $self->top_compiled_unit;
}

method compile_expression (Object $expr, Object $env) {
    return $expr->compile($self, $env, allow_definitions => 1);
}

method build_top_environment {
    return TopEnvironmentClass->new;
}

method build_top_compiled_unit {
    return CompiledUnitClass->new;
}

my $CheckQuoteArg = method (Object $tree: Str $name) {

    # require one argument
    $tree->throw_parse_error(
        invalid_argument_count => sprintf('Invalid argument count: %s expected 1, received %d', $name, $tree->content_count - 1),
    ) unless $tree->content_count == 2;

    # return quote argument
    return $tree->get_content_item(1);
};

method quote_tree (Object $tree, Object $env, Bool :$allow_unquote) {
    
    # tree must be quotable
    $tree->throw_parse_error(unquotable => sprintf('Unquotable object: %s', ref $tree))
        unless $tree->does('Script::SXC::Tree::Quotability');

    # look for unquotes if quasiquoting and possible on this element
    if ($allow_unquote and $tree->isa('Script::SXC::Tree::List')) {

        # check for a symbol at the beginning
        if ($tree->content_count > 0 and (my $sym = $tree->get_content_item(0))->isa('Script::SXC::Tree::Symbol')) {

            # simple unquote
            if ($sym->value eq 'unquote') {
                return $CheckQuoteArg->($tree, $sym->value)->compile($self, $env);
            }

            # splicing unquote
            if ($sym->value eq 'unquote-splicing') {
                return CompiledValues->new(expression => $CheckQuoteArg->($tree, $sym->value)->compile($self, $env));
            }
        }
    }

    return $tree->quoted($self, $env, allow_unquote => $allow_unquote);
}

method compile_optimized_sequence (Object $env!, ArrayRef $exprs!, %opt) {

    my $cnt = 0;
    return [ map {
        $cnt++;
        $_->compile($self, $env,
          ( ($opt{optimize_tailcalls} and $cnt == @$exprs) 
            ? (optimize_tailcalls => 1)
            : ()
          ),
        );
    } @{ $exprs } ];
};

__PACKAGE__->meta->make_immutable;

1;
