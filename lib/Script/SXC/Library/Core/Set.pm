=head1 NAME

Script::SXC::Library::Core::Set - Modification of a Variable

=cut

package Script::SXC::Library::Core::Set;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 set!

=cut

CLASS->add_inliner('set!', via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, Object :$symbol!, :$error_cb) {

    CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);

    # must be two arguments
    $error_cb->('invalid_argument_count', message => sprintf('Invalid argument count to %s call: Got %d, expected 2', $name, scalar(@$exprs)))
        unless @$exprs == 2;

    # split up arguments
    my ($var, $expr) = @$exprs;

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
