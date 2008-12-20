=head1 NAME

Script::SXC::Library::Core::Quoting - Core Quoting Functionality

=cut

package Script::SXC::Library::Core::Quoting;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 quote

=head2 quasiquote

=cut

CLASS->add_inliner([qw( quote quasiquote )], via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!) {

    # we only expect one expression
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

    # return quoted expression
    return $compiler->quote_tree($exprs->[0], $env, allow_unquote => ($name eq 'quasiquote'));
});

=head2 unquote

=head2 unquote-splicing

=cut

CLASS->add_inliner([qw( unquote unquote-splicing )], via => method (:$error_cb!, Str :$name!, Object :$symbol!) {

    # just throw an error, since we can't unquote outside of a quasiquote
    $error_cb->('invalid_unquote', message => "Invalid $name outside of quasiquoting", source => $symbol);
});

1;
