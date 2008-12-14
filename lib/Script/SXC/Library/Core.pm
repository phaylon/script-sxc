package Script::SXC::Library::Core;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use CLASS;
use Perl6::Junction qw( any );
use Scalar::Util    qw( blessed );

use Script::SXC::Runtime;

use aliased 'Script::SXC::Compiled::Value',             'CompiledValue';
use aliased 'Script::SXC::Compiled::Conditional',       'CompiledConditional';
use aliased 'Script::SXC::Compiled::Scope',             'CompiledScope';
use aliased 'Script::SXC::Compiled::Function',          'CompiledFunction';
use aliased 'Script::SXC::Compiled::Goto',              'CompiledGoto';
use aliased 'Script::SXC::Compiled::Application',       'CompiledApply';
use aliased 'Script::SXC::Compiled::TypeCheck',         'CompiledTypeCheck';
use aliased 'Script::SXC::Signature',                   'Signature';
use aliased 'Script::SXC::Exception::ParseError',       'ParseError';
use aliased 'Script::SXC::Exception::TypeError',        'TypeError';
use aliased 'Script::SXC::Exception::ArgumentError',    'ArgumentError';

use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

my $CheckArgCount = method ($cb: Str $name!, ArrayRef $exprs!, Int $expected!) {
    $cb->('invalid_argument_count', 
        message => sprintf('Invalid argument count: %s expected %d, received %d', $name, $expected, scalar(@$exprs)),
    ) unless @$exprs == $expected;
};

my $RuntimeErrorCB = sub { #method (Str $type: Str :$message!, Int :$up = 0) {
    my ($type, %args)  = @_;
    my ($message, $up) = @args{qw( message up )};
    $up //= 1;
    ArgumentError->throw_to_caller(type => $type, message => $message, up => $up + 1);
};

my $ArgTypeError = method (Str $name: Str $message!, Int $up = 1) {
    @_ = ('argument_type_error', message => "Argument type error in $name call: $message");
    goto $RuntimeErrorCB;
};

#
#   operators
#

CLASS->add_inliner('or',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls, :$error_cb!, Str :$name!) {
        return CompiledValue->new(
            content => sprintf '(%s)', 
                CLASS->undef_when_empty(join(' or ', 
                    map  { $_->render } 
                    @{ $compiler->compile_optimized_sequence($env, $exprs, optimize_tailcalls => $optimize_tailcalls) },
                )),
        );
    },
);

CLASS->add_inliner('and',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls) {
        return CompiledValue->new(
            content => sprintf '(%s)', 
                CLASS->undef_when_empty(join(' and ', 
                    map  { $_->render } 
                    @{ $compiler->compile_optimized_sequence($env, $exprs, optimize_tailcalls => $optimize_tailcalls) },
                )),
        );
    },
);

CLASS->add_inliner('err', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb, :$name) {

    return CompiledValue->new(content => sprintf '(%s)', CLASS->undef_when_empty(
        join ' // ', map { $_->compile($compiler, $env)->render } @$exprs,
    ));
});

CLASS->add_inliner('def', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb, :$name) {

    return CompiledValue->new(content => sprintf '(%s)', CLASS->undef_when_empty(
        join ' and ', map { sprintf 'defined(%s)', $_->compile($compiler, $env)->render } @$exprs,
    ));
});

CLASS->add_inliner('not',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs) {
        return CompiledValue->new(
            content => sprintf  '(%s)', 
                CLASS->undef_when_empty(join(' and ', 
                    map  { sprintf 'not(%s)', $_->compile($compiler, $env)->render }
                    @{ $exprs },
                )),
        );
    },
);

CLASS->add_inliner('begin',
    via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs, Str :$name!, :$error_cb!, :$optimize_tailcalls) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        return $env->build_scope_with_definitions(CompiledScope,
            $compiler,
            $exprs,
            [],
            compile_params => {
                allow_definitions   => 1,
                optimize_tailcalls  => $optimize_tailcalls,
            },
        );
    },
);

#
#   conditionals
#

CLASS->add_inliner('if',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls, Str :$name!, :$error_cb!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 3);

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

{   my $lambda_via = method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);

        # the expression list consists of a signature specification and body expressions
        my ($sig_spec, @body) = @$exprs;

        # build the signature from the spec
        my $sig = Signature->new_from_tree($sig_spec, $compiler, $env);

        # build definition map out of parameter signature
        my $definition_map = $sig->as_definition_map;

        # build a function scope
        return $env->build_scope_with_definitions(CompiledFunction,
            $compiler, 
            \@body,
            $definition_map, 
            validation_source   => $sig,
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

    # makes no sense if there are no pairs in list
    $error_cb->($error_type, message => "Invalid variable specification for $name: Pairs expected", source => $expr)
        unless $expr->content_count;

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

    return \@pairs;
};

# TODO finish up helper info for let-misuse
my $HandleLetError = sub {
    my ($error, $name, $vars, $last_def) = @_;

    # nothing else to say here
    die $error 
        if $name eq 'let-rec';

    # this error was about an unbound variable
    if (blessed($error) and $error->isa('Script::SXC::Exception::UnboundVar')) {

        # build a lookup table for the variable names
        my %vars = map {( $_->[0]->value, 1 )} @$vars;

        # let and let* check for let-rec compatibility
        if ($name eq any(qw( let let* )) and $last_def and $error->name eq $last_def->value) {
            $error->message(sprintf '%s (%s)', $error->message, 'did you mean to use let-rec instead?');
        }

        # let checks for let* compatibility
        elsif ($name eq 'let' and $vars{ $error->name }) {
            $error->message(sprintf '%s (%s)', $error->message, 'did you mean to use let* instead?');
        }
    }

    die $error;
};

for my $let ('let*', 'let-rec') {
    CLASS->add_inliner($let, via => 
        method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!, :$optimize_tailcalls, Object :$symbol!) {

        # remember last defined symbol
        my $last_def_symbol;

        # need var spec and at least one expression
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);

        # var list, then scope body
        my ($var_spec, @body) = @$exprs;

        # parse the spec
        my $pairs = $ParseLetVarSpec->($self, $var_spec, $name, $compiler, $env, $error_cb);

        # this fixes up our pairs, the double-arrayref is necessary, since it's a pair in a list
        my $fixpair = sub {
            my ($pair, $env) = @_;
            $last_def_symbol = $pair->[0];                                          # let-rec doesn't need this info
            return [[ 
                $pair->[0], 
                ( ($name eq 'let*')                                                 # let-rec compiles after symbol definition
                  ? $pair->[1]->compile($compiler, $env)
                  : sub { $pair->[1]->compile($compiler, $_[0]) }
                ),
            ]];
        };

        # the first built scope gets passed a callback that renders the subsequent ones
        my $scope = eval { 
            $env->build_scope_with_definitions(CompiledScope,
                $compiler, 
                \@body, 
                $fixpair->(shift(@$pairs), $env),                                       # reformat pair
              ( @$pairs ? (body_cb => method (Object :$scope_env!, :$body_cb) {
                    my $next_pair = shift @$pairs;

                    # we need to return an arrayref of expressions
                    return [ $scope_env->build_scope_with_definitions(CompiledScope,
                        $compiler,
                        \@body,
                        $fixpair->($next_pair, $scope_env),                             # reformat pair
                      ( @$pairs ? (body_cb => $body_cb) : () ),                         # only pass cb if not last pair
                    ) ];
                }) : () ),
            );
        };

        # was there a problem during the scope build?
        if (my $error = $@) {
            $HandleLetError->($error, $name, $pairs, $last_def_symbol);
        }

        return $scope;
    });
}

CLASS->add_inliner('let', via => 
    method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb, :$optimize_tailcalls) {

    # remember last defined symbol
    my $last_def_sym;

    # need var spec and at least one expression
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);

    # first object is the var list, the rest is the body
    my ($var_spec, @body) = @$exprs;

    # parse the variable specification
    my $pairs = $ParseLetVarSpec->($self, $var_spec, $name, $compiler, $env, $error_cb);

    # create scope
    my $scope = eval {

        # compile the expressions
        $last_def_sym = $_->[0] and $_->[1] = $_->[1]->compile($compiler, $env)
            for @$pairs;

        $env->build_scope_with_definitions(CompiledScope, 
            $compiler, \@body, $pairs,
            compile_params => { optimize_tailcalls => $optimize_tailcalls },
        );
    };

    # was there an error?
    if (my $error = $@) {
        $HandleLetError->($error, $name, $pairs, $last_def_sym);
    }

    return $scope;
});

CLASS->add_inliner('set!', via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, Object :$symbol!, :$error_cb) {

    CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);

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
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

    # return quoted expression
    return $compiler->quote_tree($exprs->[0], $env, allow_unquote => ($name eq 'quasiquote'));
});

CLASS->add_inliner([qw( unquote unquote-splicing )], via => method (:$error_cb!, Str :$name!, Object :$symbol!) {

    $error_cb->('invalid_unquote', message => "Invalid $name outside of quasiquoting", source => $symbol);
});

#
#   goto
#

CLASS->add_inliner('goto', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);

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

my $TransformLambdaDefinition;
$TransformLambdaDefinition = method (Object $signature: ArrayRef $body!, Str $define!) {

    # deref to make transformation safer
    my @body = @$body;

    # obviously this cannot be empty
    $signature->throw_parse_error(invalid_definition_signature => "Signature list cannot be empty for $define")
        unless $signature->content_count;

    # split up the signature parts
    my ($name, @params) = @{ $signature->contents };

    # if the name was a list we are a generator
    if ($name->isa('Script::SXC::Tree::List')) {

        # get to next level do build generated lambda
        ($name, @body) = $TransformLambdaDefinition->($name, [@body], $define);
    }

    $name->throw_parse_error(invalid_variable_name => "Invalid variable name: Name must be symbol")
        unless $name->isa('Script::SXC::Tree::Symbol');

    # build lambda expression
    my $lambda = $signature->new_item_with_source(List => { contents => [
        $signature->new_item_with_source(Builtin => { value    => 'lambda' }),
        $signature->new_item_with_source(List    => { contents => \@params }),
        @body,
    ]});

    # return name and lambda expression
    return $name, $lambda;
};

CLASS->add_inliner('define', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, Bool :$allow_definitions!, :$name) {

    # check if we are allowed to define here
    $error_cb->('illegal_definition', message => 'Illegal definition: Definitions only allowed on top-level or as expression in a lambda body')
        unless $allow_definitions;

    # argument count
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);

    # lambda shortcut definitino
    if ($exprs->[0]->isa('Script::SXC::Tree::List')) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);

        # split up signature(s) and body
        my ($sig, @body) = @$exprs;

        # transform shortcut to name and lambda
        my ($name, $lambda) = $TransformLambdaDefinition->($sig, \@body, $name);
    
        # build the new definition
        return $env->build_definition($compiler, $name, $lambda, compile_expr => sub { $lambda->compile($compiler, $env) });
    }

    # direct definition
    elsif ($exprs->[0]->isa('Script::SXC::Tree::Symbol')) {

        # direct definition can only take two arguments (symbol and value)
        CLASS->check_arg_count($error_cb, $name, $exprs, max => 2);

        # split up
        my ($sym, $expr) = (
            @$exprs == 2 
            ? @$exprs 
            : ( $exprs->[0], $exprs->[0]->new_item_with_source(Boolean => { value => 0 }) )
        );
    
        # create definition
        return $env->build_definition($compiler, $sym, $expr, compile_expr => sub { $expr->compile($compiler, $env) });
    }

    # something else
    $exprs->[0]->throw_parse_error(invalid_definition_target => "First argument to $name must be list or symbol");
});

#
#   contexts
#

CLASS->add_inliner('values->list', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name!, :$error_cb!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

    my $ls = $exprs->[0];
    $error_cb->('invalid_expression', message => "Invalid expression as argument to $name: Expected application", source => $ls)
        unless $ls->isa('Script::SXC::Tree::List');

    return $ls->compile($compiler, $env, return_type => 'list');
});

CLASS->add_inliner('values->hash', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name!, :$error_cb!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

    my $hs = $exprs->[0];
    $error_cb->('invalid_expression', message => "Invalid expression as argument to $name: Expected application", source => $hs)
        unless $hs->isa('Script::SXC::Tree::List');

    return $hs->compile($compiler, $env, return_type => 'hash');
});

#
#   application
#

CLASS->add_procedure('apply',
    firstclass  => Script::SXC::Runtime->can('apply'),
    inliner     => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        my ($invocant, @args) = @$exprs;

        my $last_arg = pop @args;

        # TODO last arg must be list
        return CompiledApply->new_from_uncompiled(
            $compiler,
            $env,
            invocant    => $invocant,
            arguments   => [
                @args,
                CompiledValue->new(content => sprintf '(@{( %s )})',
                    CompiledTypeCheck->new(
                        expression  => $last_arg->compile($compiler, $env),
                        type        => 'list',
                        source_item => $last_arg,
                        message     => "Invalid argument type: Last argument to $name must be a list",
                    )->render,
                ),
            ],
            tailcalls                   => $compiler->optimize_tailcalls,
            return_type                 => 'scalar',
            inline_invocant             => 0,
            inline_firstclass_args      => 0,
            $symbol->source_information,
            options => {
                optimize_tailcalls  => $compiler->optimize_tailcalls,
                first_class         => $compiler->force_firstclass_procedures,
                source              => $self,
            },
        );
    },
);

#
#   recursion
#

CLASS->add_inliner('recurse', via => method 
    (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, Str :$name!, Object :$symbol!, :$optimize_tailcalls) {

    # we at least expect a symbol, a list of pairs and a body
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 3);
    my ($name_sym, $vars, @body) = @$exprs;

    # symbol can only be that
    $name_sym->throw_parse_error(invalid_variable_name => "Invalid variable name: Expected a symbol as first argument to $name")
        unless $name_sym->isa('Script::SXC::Tree::Symbol');

    # variable list type checks
    $vars->throw_parse_error(invalid_variable_list => "Invalid variable list: Expected a list as second argument to $name")
        unless $vars->isa('Script::SXC::Tree::List');

    # transform parameters
    my (@params, @init_values);
    for my $x (0 .. $#{ $vars->contents }) {

        # check pair
        my $pair = $vars->get_content_item($x);
        $pair->throw_parse_error(invalid_variable_specification => "Invalid variable specification: Pair expected in $name variable list")
            unless $pair->isa('Script::SXC::Tree::List') and $pair->content_count == 2;

        # store the parts
        push @params,      $pair->get_content_item(0);
        push @init_values, $pair->get_content_item(1);
    }

    # build new tree
    my $recurse = $name_sym->new_item_with_source(List => { contents => [
        $name_sym->new_item_with_source(Builtin => { value => 'let-rec' }),
        $name_sym->new_item_with_source(List => { contents => [
            $name_sym->new_item_with_source(List => { contents => [
                $name_sym,
                $name_sym->new_item_with_source(List => { contents => [
                    $name_sym->new_item_with_source(Builtin => { value => 'lambda' }),
                    $vars->new_item_with_source(List => { contents => \@params }),
                    @body,
                ]}),
            ]}),
        ]}),
        $name_sym->new_item_with_source(List => { contents => [
            $name_sym,
            @init_values,
        ]}),
    ]});

    # compile recursion
    return $recurse->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls);
});

CLASS->add_inliner('builtin', via => method (:$compiler!, :$env!, :$name!, :$exprs!, :$error_cb!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
    my $symbol = $exprs->[0];

    $symbol->throw_parse_error(invalid_builtin_name => "Invalid builtin name: $name expected symbol")
        unless $symbol->isa('Script::SXC::Tree::Symbol');

    return $symbol->compile($compiler, $compiler->top_environment);
});

CLASS->add_procedure('display', firstclass => sub { print @_, "\n" });


# TODO still missing:
#   * core;
#   - (given (get-foo) 
#      (ref?                            "ref") 
#      ((and (list? _) (< 0 (size _)))  (list-ref _ 1)) 
#      (default                         #f))
#   - (cond ((< x 23) :smaller)
#           ((> x 23) :larger)
#           (else     :equal))
#   - (cond ((foo) => do-with-foo)
#           (else  => do-with-else))
#   - (cond test: defined?
#      (foo  :foo)
#      (else :bar))
#   - (state ((x (foo))) x)
#   - (try (λ () (foo 23))
#          (λ (e) (isa: e "My::Error"))         ; could also be (catch class! ...)
#          (λ (e) (say (message: e))))
#   - (sleep 0.1)
#   * OO
#   - (package Foo::Bar
#      (exports
#       (foo: make-foo foo? foo-value)
#       (default: find-some-foo)))
#   - (class Bar::Baz :is-immutable
#      (extends BaseA BaseB)
#      (with RoleA RoleB)
#      (has id isa:      Int
#              required: 1
#              builder:  build_default_id)
#      (method (build_default_id self)
#        23)
#      (multimethod (add (Str a) (Str b))
#       (string a b))
#      (multimethod (add (Int a) (Int b))
#       (+ a b)))
#      (method (sub x y) (- x y))
#   - (role RoleA
#      (multimethod (add a b)
#       (croak "Unable to find a way to add $(typa a) to $(type b)")))
#   * I/O
#   - (with-input-port port
#      (do :something))
#   - (with-standard-output-port
#      (do :something))
#   - (say "foo" "bar)
#   - (print (string "foo" "bar") *stdin*)
#   - (path "foo" "bar")
#   - (file "foo" "bar" "baz.txt")
#   * Math
#   * standalone compiler
#   * inline compiler
#   * regular expressions
#   - (define rx ~/^foo(.*)oo$/i)
#   - (replace: rx "bar${1}baz" :global)
#   * runtime compilation
#   * runtime types
#   * macros
#   * eval
#   - (eval '(+ 2 3))                   => 5
#     (let ((foo (λ (n) (list n))))
#      (eval '(foo 23) :inject foo))    => (23)
#     (let ((foo (λ (n) (* n n))))
#      (eval '(foo 3) :inject-all))     => 9
#   - (eval-string "(+ 2 3)")           => 5

__PACKAGE__->meta->make_immutable;

1;
