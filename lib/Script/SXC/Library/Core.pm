package Script::SXC::Library::Core;
use Moose;
use MooseX::Method::Signatures;

use CLASS;

use aliased 'Script::SXC::Compiled::Value',         'CompiledValue';
use aliased 'Script::SXC::Compiled::Conditional',   'CompiledConditional';
use aliased 'Script::SXC::Compiled::Scope',         'CompiledScope';
use aliased 'Script::SXC::Compiled::Function',      'CompiledFunction';
use aliased 'Script::SXC::Compiled::Goto',          'CompiledGoto';
use aliased 'Script::SXC::Signature',               'Signature';
use aliased 'Script::SXC::Exception::ParseError',   'ParseError';
use aliased 'Script::SXC::Exception::TypeError',    'TypeError';

use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

my $CheckArgCount = method ($cb: Str $name!, ArrayRef $exprs!, Int $expected!) {

    $cb->('invalid_argument_count', 
        message => sprintf('Invalid argument count: %s expected %d, received %d', $name, $expected, scalar(@$exprs)),
    ) unless @$exprs == $expected;
};

#
#   operators
#

CLASS->add_inliner('or',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls) {
        return CompiledValue->new(
            content => sprintf '(%s)', 
                join ' or ', 
                map  { $_->render } 
                @{ $compiler->compile_optimized_sequence($env, $exprs, optimize_tailcalls => $optimize_tailcalls) }
        );
    },
);

CLASS->add_inliner('and',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls) {
        return CompiledValue->new(
            content => sprintf '(%s)', 
                join ' and ', 
                map  { $_->render } 
                @{ $compiler->compile_optimized_sequence($env, $exprs, optimize_tailcalls => $optimize_tailcalls) }
        );
    },
);

CLASS->add_inliner('not',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs) {
        return CompiledValue->new(
            content => sprintf  '(%s)', 
                join ' and ', 
                map  { sprintf 'not(%s)', $_->compile($compiler, $env)->render }
                @{ $exprs }
        );
    },
);

#
#   conditionals
#

CLASS->add_inliner('if',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls) {
        # TODO check args, throw exceptions
        my ($cnd, $csq, $alt) = @$exprs;

        return CompiledConditional->new(
            condition   => $cnd->compile($compiler, $env),
            consequence => $csq->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls),
           ( $alt ? (alternative => $alt->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls)) : () ),
        );
    },
);

#
#   lambdas
#

{   my $lambda_via = method (Object :$compiler, Object :$env, Str :$name, ArrayRef :$exprs) {

        # the expression list consists of a signature specification and body expressions
        my ($sig_spec, @body) = @$exprs;

        # build the signature from the spec
        my $sig = Signature->new_from_tree($sig_spec);

        # build definition map out of parameter signature
        my $definition_map = $sig->as_definition_map;

        # build a function scope
        return $env->build_scope_with_definitions(CompiledFunction, 
            $compiler, 
            \@body,
            $definition_map, 
            additional_params   => { 
                signature           => $sig,
            },
            compile_params      => { 
                allow_definitions   => 1, 
                optimize_tailcalls  => $compiler->optimize_tailcalls,
            },
        );
    };

    CLASS->add_inliner($_, via => $lambda_via)
        for qw( lambda λ );
}

my $ParseLetVarSpec = method (Object $expr!, Str $name!, Object $compiler!, Object $env!, $error_cb!) {
    my $error_type = 'invalid_variable_specification';

    # variable specification must be list
    $error_cb->($error_type, message => "Invalid variable specification for $name: List expected", source => $expr)
        unless $expr->isa('Script::SXC::Tree::List');

    # this stores the finished structure we return
    my @pairs;

    # walk the items of the list
    for my $idx (0 .. $expr->content_count - 1) {
        my $pair = $expr->get_content_item($idx);

        # this item has to be a list
        $error_cb->($error_type, 
            message => "Invalid variable specification for $name: Pair expected at element $idx of variable list",
            source  => $pair)
          unless $pair->isa('Script::SXC::Tree::List') and $pair->content_count == 2;

        # split up symbol and its expression
        my ($var_spec, $var_expr) = @{ $pair->contents };

        # TODO in-structure definition should be possible

        # require symbol for the moment
        $error_cb->($error_type,
            message => "Invalid variable specification for $name: Symbol expected as variable name in pair at element $idx",
            source  => $var_spec)
          unless $var_spec->isa('Script::SXC::Tree::Symbol');

        push @pairs, [$var_spec, $var_expr];
    }

    # TODO can't work without any pairs at all, check that.

    return \@pairs;
};

CLASS->add_inliner('let*', via => 
    method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!, :$optimize_tailcalls) {

    # var list, then scope body
    my ($var_spec, @body) = @$exprs;

    # parse the spec
    my $pairs = $ParseLetVarSpec->($self, $var_spec, $name, $compiler, $env, $error_cb);

    # this fixes up our pairs, the double-arrayref is necessary, since it's a pair in a list
    my $fixpair = sub {
        my ($pair, $env) = @_;
        return [[ $pair->[0], $pair->[1]->compile($compiler, $env) ]];
    };

    # the first built scope gets passed a callback that renders the subsequent ones
    return $env->build_scope_with_definitions(CompiledScope,
        $compiler, 
        \@body, 
        $fixpair->(shift(@$pairs), $env),                                       # reformat pair
#        compile_params => { 
#            optimize_tailcalls => $optimize_tailcalls,
#        },
      ( @$pairs ? (body_cb => method (Object :$scope_env!, :$body_cb) {
            my $next_pair = shift @$pairs;

            # we need to return an arrayref of expressions
            return [ $scope_env->build_scope_with_definitions(CompiledScope,
                $compiler,
                \@body,
                $fixpair->($next_pair, $scope_env),                             # reformat pair
              ( @$pairs ? (body_cb => $body_cb) : () ),                         # only pass cb if not last pair
#                compile_params => { 
#                    optimize_tailcalls => $optimize_tailcalls,
#                },
            ) ];
        }) : () ),
    );
});

CLASS->add_inliner('let', via => 
    method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb, :$optimize_tailcalls) {

    # first object is the var list, the rest is the body
    my ($var_spec, @body) = @$exprs;

    # parse the variable specification
    my $pairs = $ParseLetVarSpec->($self, $var_spec, $name, $compiler, $env, $error_cb);

    # compile the expressions
    $_->[1] = $_->[1]->compile($compiler, $env)
        for @$pairs;

    # create scope
    return $env->build_scope_with_definitions(CompiledScope, 
        $compiler, \@body, $pairs,
        compile_params => { optimize_tailcalls => $optimize_tailcalls },
    );
});

CLASS->add_inliner('set!', via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, Object :$symbol!, :$error_cb) {

    # must be two arguments
    $error_cb->('invalid_argument_count', message => sprintf('Invalid argument count to %s call: Got %d, expected 2', $name, scalar(@$exprs)))
        unless @$exprs == 2;

    # split up arguments
    my ($var, $expr) = @$exprs;

    # first argument must be a symbol
    $error_cb->('invalid_modification_target', message => 'Modification target is not a symbol')
        unless $var->isa('Script::SXC::Tree::Symbol');

    # compile symbol and expression
    $$_ = $$_->compile($compiler, $env)
        for \($var, $expr);
    
    # return a compiled modification object
    return $env->build_modification($var, $expr);
});

#
#   quoting
#

CLASS->add_inliner([qw( quote quasiquote )], via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!) {

    # we only expect one expression
    $CheckArgCount->($error_cb, $name, $exprs, 1);

    # return quoted expression
    return $compiler->quote_tree($exprs->[0], $env, allow_unquote => ($name eq 'quasiquote'));
});

#
#   goto
#

CLASS->add_inliner('goto', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!) {

    # make sure we have at least one argument
    $error_cb->('invalid_argument_count', message => 'Invalid argument count: goto needs at least 1 argument')
        unless @$exprs;

    # we need at least a target, plus an optional number of arguments
    my ($target, @args) = @$exprs;

    # return compiled jump
    return CompiledGoto->new(
        invocant  => $target->compile($compiler, $env),
        arguments => [map { $_->compile($compiler, $env) } @args],
    );
});

#
#   definitions
#

CLASS->add_inliner('define', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, Bool :$allow_definitions!) {

    # check if we are allowed to define here
    $error_cb->('illegal_definition', message => 'Illegal definition: Definitions only allowed on top-level or as expression in a lambda body')
        unless $allow_definitions;

    # TODO extended definitions

    # split up
    my ($sym, $expr) = @$exprs;
    
    # create definition
    return $env->build_definition($compiler, $sym, $expr, compile_expr => sub { $expr->compile($compiler, $env) });
});

#
#   contexts
#

CLASS->add_inliner('values->list', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {

    my $ls = $exprs->[0];
    return $ls->compile($compiler, $env, return_type => 'list');
});

CLASS->add_inliner('values->hash', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {

    my $hs = $exprs->[0];
    return $hs->compile($compiler, $env, return_type => 'hash');
});

__PACKAGE__->meta->make_immutable;

1;
