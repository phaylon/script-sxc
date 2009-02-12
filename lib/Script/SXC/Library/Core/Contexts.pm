=head1 NAME

Script::SXC::Library::Core::Contexts - Core Non-Scalar Context Calls

=cut

package Script::SXC::Library::Core::Contexts;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use constant ListClass => 'Script::SXC::Tree::List';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 values->list

=cut

CLASS->add_inliner('values->list', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name!, :$error_cb!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

    my $ls = $exprs->[0];
    $error_cb->('invalid_expression', message => "Invalid expression as argument to $name: Expected application", source => $ls)
        unless $ls->isa(ListClass);

    return $ls->compile($compiler, $env, return_type => 'list');
});

=head2 values->hash

=cut

CLASS->add_inliner('values->hash', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name!, :$error_cb!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

    my $hs = $exprs->[0];
    $error_cb->('invalid_expression', message => "Invalid expression as argument to $name: Expected application", source => $hs)
        unless $hs->isa(ListClass);

    return $hs->compile($compiler, $env, return_type => 'hash');
});

__PACKAGE__->meta->make_immutable;

1;
