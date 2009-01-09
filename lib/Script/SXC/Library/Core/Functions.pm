=head1 NAME

Script::SXC::Library::Core::Functions - Core Function Management

=cut

package Script::SXC::Library::Core::Functions;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Signature',
    ['Script::SXC::Compiled::Function', 'CompiledFunction'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 lambda

Syntax:

  (lambda <parameters> <body> …)

TODO fix up documentation

=cut

{   my $lambda_via = method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);

        # the expression list consists of a signature specification and body expressions
        my ($sig_spec, @body) = @$exprs;

        # build the signature from the spec
        my $sig = Signature->new_from_tree($sig_spec, $compiler, $env);

        # build definition map out of parameter signature
        my $definition_map = $sig->as_definition_map;

        # build a function scope
        return $env->build_scope_with_definitions(CompiledFunction,
            $compiler, 
            \@body,
            $definition_map, 
            validation_source   => $sig,
            additional_params   => { 
                signature           => $sig,
            },
            compile_params      => { 
                allow_definitions   => 1, 
                optimize_tailcalls  => $compiler->optimize_tailcalls,
            },
        );
    };

    CLASS->add_inliner($_, via => $lambda_via)
        for qw( lambda λ );
}

for my $chunk_name (qw( chunk λ… )) {
    CLASS->add_inliner($chunk_name, via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb!, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        return $symbol->new_item_with_source(List => { contents => [
            $symbol->new_item_with_source(Builtin => { value => 'lambda' }),
            $symbol->new_item_with_source(List    => { contents => [] }),
            @$exprs,
        ]})->compile($compiler, $env);
    });
}

1;
