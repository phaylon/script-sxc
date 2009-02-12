=head1 NAME

Script::SXC::Library::Core::Definitions - Core Variable Definition Functionality

=cut

package Script::SXC::Library::Core::Definitions;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use constant ListClass   => 'Script::SXC::Tree::List';
use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

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
    if ($name->isa(ListClass)) {

        # get to next level do build generated lambda
        ($name, @body) = $TransformLambdaDefinition->($name, [@body], $define);
    }

    $name->throw_parse_error(invalid_variable_name => "Invalid variable name: Name must be symbol")
        unless $name->isa(SymbolClass);

    # build lambda expression
    my $lambda = $signature->new_item_with_source(List => { contents => [
        $signature->new_item_with_source(Builtin => { value    => 'lambda' }),
        $signature->new_item_with_source(List    => { contents => \@params }),
        @body,
    ]});

    # return name and lambda expression
    return $name, $lambda;
};

=head1 SYNTAX ELEMENTS

=head2 define

=cut

CLASS->add_inliner('define', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, Bool :$allow_definitions!, :$name) {

    # check if we are allowed to define here
    $error_cb->('illegal_definition', message => 'Illegal definition: Definitions only allowed on top-level or as expression in a lambda body')
        unless $allow_definitions;

    # argument count
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);

    # lambda shortcut definitino
    if ($exprs->[0]->isa(ListClass)) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);

        # split up signature(s) and body
        my ($sig, @body) = @$exprs;

        # transform shortcut to name and lambda
        my ($name, $lambda) = $TransformLambdaDefinition->($sig, \@body, $name);
    
        # build the new definition
        return $env->build_definition($compiler, $name, $lambda, compile_expr => sub { $lambda->compile($compiler, $env) });
    }

    # direct definition
    elsif ($exprs->[0]->isa(SymbolClass)) {

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

__PACKAGE__->meta->make_immutable;

1;
