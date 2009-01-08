package Script::SXC::Compiler::Environment;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose    qw( Str ArrayRef HashRef Object );

use CLASS;
use Scalar::Util qw( weaken refaddr );

use constant VariableClass => 'Script::SXC::Compiler::Environment::Variable';

use Script::SXC::lazyload
    VariableClass,
    'Script::SXC::Compiler::Environment::Variable::Outer',
    'Script::SXC::Compiler::Environment::Definition',
    'Script::SXC::Compiler::Environment::Modification',
    ['Script::SXC::Exception::UnboundVar', 'UnboundVarException'];

use namespace::clean -except => 'meta';

has parent => (
    is          => 'ro',
    isa         => CLASS,
    required    => 1,
);

has _variables => (
    metaclass   => 'Collection::Hash',
    is          => 'rw',
    isa         => HashRef,
    required    => 1,
    builder     => 'build_default_variables',
    provides    => {
        'keys'      => 'variable_names',
        'values'    => 'variables',
        'get'       => 'get_variable',
        'set'       => 'set_variable',
        'exists'    => 'has_variable',
    },
);

has child_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    default     => __PACKAGE__,
    handles     => {
        'build_child_object' => 'new',
    },
);

method create_variable (Object $symbol, HashRef :$params = {}) {
    return $symbol
        if $symbol->isa(VariableClass);

    my $name = $symbol->value;
    
    $symbol->throw_parse_error(invalid_dot_symbol => 'The dot symbol is reserved and cannot be used as an identifier')
        if $name eq '.';

    # create new variable object
    my $var = Variable->new_from_name($name, %$params);

    # store variable
    $self->set_variable($name, $var);

    # return it
    return $var;
}

method new_child {

    # return a new child with this env as parent
    return $self->build_child_object(parent => $self);
}

subtype 'Script::SXC::DefinitionMap',
    from    ArrayRef,
    where   { 
        not(@$_ % 2)
        and do { 
            my @p = @$_; 
            while (my $v = shift @p) { 
                is_Str $v or return;
                is_Object shift @p or return;
            }
        } 
    },
    message { 
        'DefinitionMaps must be ArrayRefs with Str/Object pairs' 
    };

method build_modification (Object $var!, Object $expr!) {

    # forcibly typehint the variable. if there's no typehint, it will be cleared
    $var->try_typehinting_from($expr, or_clear => 1);

    # return the compiled modification
    return Modification->new(variable => $var, expression => $expr);
}

method build_definition (Object $compiler!, Object $symbol!, Object $expr!, CodeRef :$compile_expr?) {

    # create a new variable
    my $var = $self->create_variable($symbol, params => { prefix => 'def' });

    # do we have to compile the expression here?
    if ($compile_expr) {
        $expr = $compile_expr->();
    }

    # try to typehint
    $var->try_typehinting_from($expr);

    # build compiled definition object
    return Definition->new(
        variable    => $var,
        expression  => $expr,
    );
}

method build_scope_with_definitions 
    (Str $scope_class, Object $compiler, ArrayRef $body, ArrayRef $defs, HashRef :$additional_params = {}, :$body_cb?, HashRef :$compile_params = {}, Object :$validation_source?) {

    # split up definitions in name/expr pairs
    my @def_pairs = @$defs;

    # build child environment
    my $scope_env = $self->new_child;

    # create variables in new environment
    $_->[0] = $scope_env->create_variable($_->[0])
        for @def_pairs;

    # build compiled definitions
    my @compiled_defs
      = map {
            my $expr = ( (ref $_->[1] eq 'CODE') ? $_->[1]->($scope_env) : $_->[1] );
            $_->[0]->try_typehinting_from($expr);
            Definition->new(variable => $_->[0], expression => $expr);
        }
        @def_pairs;

    # expressions are either from compiled body or callback
    my $_cnt    = 0;
    my $_tc_opt = delete $compile_params->{optimize_tailcalls};
    my $expressions 
      = $body_cb
      ? $body_cb->($self,
            parent_env          => $self,
            scope_env           => $scope_env,
            body                => $body,
            definitions         => $defs,
          ( $additional_params ? %$additional_params : () ),
            body_cb             => $body_cb,
            compiler            => $compiler,
            scope_class         => $scope_class,
        )
      : [ map {
          my $pass_on_opt = $_cnt == $#$body;
          $_cnt++; 
          $_->compile(
            $compiler, 
            $scope_env, 
            %$compile_params,
            optimize_tailcalls => ($pass_on_opt ? $_tc_opt : 0),
        );
      } @$body ];

    # build new scope
    return $scope_class->new(
        environment => $scope_env,
        definitions => \@compiled_defs,
        expressions => $expressions,
      ( $validation_source 
        ? (validations => $validation_source->compile_validations($compiler, $scope_env))
        : () ),
        %$additional_params,
    );
}

method find_env_for_variable (Str $name!) {
#    warn "CHECKING ENV $self\n";

    # search locally
    if ($self->has_variable($name)) {
        return $self;
    }

    # search in parent, if we have one
    if (    $self->parent 
        and my $env = $self->parent->find_env_for_variable($name)
    ) {
        return $env;
    }

    return undef;
};

method find_variable (Str|Object $name where { not ref $_ or $_->can('value') }) {

    # if we got a symbol, use its value
    my ($sym, $orig);
    if (ref $name) {
        $sym  = $name;
#        if ($name->isa('Script::SXC::Compiler::Environment::Variable::Internal')) {
#            return $name;
#        }
        $name = $name->value;
    }

    # find environment the var is in
    my $env = $self->find_env_for_variable($name)
        or UnboundVarException->throw(
            name => $name,
          ( $sym ? $sym->source_information : () ),
        );

    # return variable
    return $self->wrap_external_variable($env->get_variable($name), $env);
};

method wrap_external_variable (Object $variable!, Object $env!) {

    # same environment, return direct var
    return $variable 
        if not($variable->isa('Script::SXC::Compiler::Environment::Variable'))
        or refaddr($self) eq refaddr($env);

    # outer variables get wrapped for typehinting adjustments
    return $variable->as_outer;
};

method build_default_variables {
    my $vars = { 
#        '*current-environment*' => $self,
#        '*environment*' => Variable->new_perl_global('ENV',  '\\%', typehint => 'hash'),
        '*arguments*'   => Variable->new_perl_global('ARGV', '\\@', typehint => 'list'),
        '*current-output-handle*' => Variable->new_perl_global('STDIN{IO}', '*'),
    };
#    weaken $vars->{ '*current-environment*' };
    return $vars;
};

__PACKAGE__->meta->make_immutable;

1;
