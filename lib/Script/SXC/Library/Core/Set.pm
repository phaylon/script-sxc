=head1 NAME

Script::SXC::Library::Core::Set - Modification of a Variable

=cut

package Script::SXC::Library::Core::Set;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Exception::ParseError';

use constant SymbolClass => 'Script::SXC::Tree::Symbol';
use constant ListClass   => 'Script::SXC::Tree::List';
use constant SetterRole  => 'Script::SXC::ProvidesSetter';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 set!

=cut

method compile_extended_setter ($class: Object $compiler!, Object $env!, Object $spec!, Object $expr!, Object $symbol!) {
    my ($setter_sym, @setter_args) = @{ $spec->contents };

    $setter_sym->throw_parse_error(invalid_setter => "Setter specification must begin with symbol")
        unless $setter_sym->isa(SymbolClass);

    my $setter_var = $compiler->top_environment->find_variable($setter_sym);

    $setter_sym->throw_parse_error(invalid_setter => "Invalid setter: '@{[ $setter_sym->value ]}'")
        unless ($setter_var->does(SetterRole) and $setter_var->can_build_setter);

    return $setter_var->build_setter($compiler, $env, \@setter_args, $expr, $symbol);
}

CLASS->add_inliner('set!', via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, Object :$symbol!, :$error_cb) {

    CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);

    # must be two arguments
    $error_cb->('invalid_argument_count', message => sprintf('Invalid argument count to %s call: Got %d, expected 2', $name, scalar(@$exprs)))
        unless @$exprs == 2;

    # split up arguments
    my ($var, $expr) = @$exprs;

    # compile an extended setter if the target spec is a list
    return CLASS->compile_extended_setter($compiler, $env, $var, $expr, $symbol)
        if $var->isa(ListClass);

    # first argument must be a symbol
    $error_cb->('invalid_modification_target', message => 'Modification target is not a symbol')
        unless $var->isa(SymbolClass);

    # compile symbol and expression
    $$_ = $$_->compile($compiler, $env)
        for \($var, $expr);

    # return a compiled modification object
    return $env->build_modification($var, $expr);
});

1;
