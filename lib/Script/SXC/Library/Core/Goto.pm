=head1 NAME

Script::SXC::Library::Core::Goto - Core Goto Functionality

=cut

package Script::SXC::Library::Core::Goto;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Goto', 'CompiledGoto'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 goto

=cut

CLASS->add_inliner('goto', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!, :$symbol!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);

    # we need at least a target, plus an optional number of arguments
    my ($target, @args) = @$exprs;

    # return compiled jump
    return CompiledGoto->new(
        invocant  => $target->compile($compiler, $env),
        arguments => [map { $_->compile($compiler, $env) } @args],
        $symbol->source_information,
    );
});

1;
