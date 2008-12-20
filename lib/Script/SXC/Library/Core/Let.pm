=head1 NAME

Script::SXC::Library::Core::Let - Core Scoping Functions

=cut

package Script::SXC::Library::Core::Let;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Scope', 'CompiledScope'];

use Scalar::Util    qw( blessed );
use Perl6::Junction qw( any );

use constant ListClass   => 'Script::SXC::Tree::List';
use constant SymbolClass => 'Script::SXC::Tree::Symbol';
use constant UnboundVar  => 'Script::SXC::Exception::UnboundVar';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

my $ParseLetVarSpec = method (Object $expr!, Str $name!, Object $compiler!, Object $env!, $error_cb!) {
    my $error_type = 'invalid_variable_specification';

    # variable specification must be list
    $error_cb->($error_type, message => "Invalid variable specification for $name: List expected", source => $expr)
        unless $expr->isa(ListClass);

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
          unless $pair->isa(ListClass) and $pair->content_count == 2;

        # split up symbol and its expression
        my ($var_spec, $var_expr) = @{ $pair->contents };

        # TODO in-structure definition should be possible

        # require symbol for the moment
        $error_cb->($error_type,
            message => "Invalid variable specification for $name: Symbol expected as variable name in pair at element $idx",
            source  => $var_spec)
          unless $var_spec->isa(SymbolClass);

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
    if (blessed($error) and $error->isa(UnboundVar)) {

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

=head1 SYNTAX ELEMENTS

=cut

=head2 let

=cut

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

=head2 let*

=head2 let-rec

=cut

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

1;
