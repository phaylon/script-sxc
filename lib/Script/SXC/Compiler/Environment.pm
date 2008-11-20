package Script::SXC::Compiler::Environment;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose    qw( Str ArrayRef HashRef Object );

use CLASS;
use Scalar::Util qw( weaken );

use aliased 'Script::SXC::Compiler::Environment::Variable';
use aliased 'Script::SXC::Compiler::Environment::Definition';
use aliased 'Script::SXC::Compiler::Environment::Modification';
use aliased 'Script::SXC::Exception::UnboundVar', 'UnboundVarException';

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

method create_variable (Str | Object $name, HashRef :$params = {}) {
    $name = $name->value if ref $name;

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
    (Str $scope_class, Object $compiler, ArrayRef $body, ArrayRef $defs, HashRef :$additional_params = {}, :$body_cb?, HashRef :$compile_params = {}) {

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
            $_->[0]->try_typehinting_from($_->[1]);
            Definition->new(variable => $_->[0], expression => $_->[1]);
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
#          warn "CNT $_cnt/$#$body+1 OPT $_tc_opt PAR $compile_params PASS $pass_on_opt TO $_\n";
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
    my $sym;
    if (ref $name) {
        $sym  = $name;
        $name = $name->value;
    }

    # find environment the var is in
    my $env = $self->find_env_for_variable($name)
        or UnboundVarException->throw(
            message => sprintf(q{Unbound variable '%s'}, $name),
          ( $sym ? $sym->source_information : () ),
        );

    # return variable
    return $env->get_variable($name);
};

method build_default_variables {
    my $vars = { '*current-environment*' => $self };
    weaken $vars->{ '*current-environment*' };
    return $vars;
};

__PACKAGE__->meta->make_immutable;

1;
