=head1 NAME

Script::SXC::Library::Core::Recursion - Core Recursion Functions

=cut

package Script::SXC::Library::Core::Recursion;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use constant ListClass   => 'Script::SXC::Tree::List';
use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 recurse

=cut

CLASS->add_inliner('recurse', via => method 
    (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, Str :$name!, Object :$symbol!, :$optimize_tailcalls) {

    # we at least expect a symbol, a list of pairs and a body
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 3);
    my ($name_sym, $vars, @body) = @$exprs;

    # symbol can only be that
    $name_sym->throw_parse_error(invalid_variable_name => "Invalid variable name: Expected a symbol as first argument to $name")
        unless $name_sym->isa(SymbolClass);

    # variable list type checks
    $vars->throw_parse_error(invalid_variable_list => "Invalid variable list: Expected a list as second argument to $name")
        unless $vars->isa(ListClass);

    # transform parameters
    my (@params, @init_values);
    for my $x (0 .. $#{ $vars->contents }) {

        # check pair
        my $pair = $vars->get_content_item($x);
        $pair->throw_parse_error(invalid_variable_specification => "Invalid variable specification: Pair expected in $name variable list")
            unless $pair->isa(ListClass) and $pair->content_count == 2;

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

__PACKAGE__->meta->make_immutable;

1;
