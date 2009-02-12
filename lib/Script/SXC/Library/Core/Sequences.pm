=head1 NAME

Script::SXC::Library::Core::Sequences - Core Sequential Functions

=cut

package Script::SXC::Library::Core::Sequences;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Scope', 'CompiledScope'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 begin

C<begin> will evaluate its arguments in a sequence, returning the value of 
the last argument. Additionally, it creates a new scope that allows definitions.

C<begin> needs at least one element to compile.

Examples:

  (begin "" #f 0 1 2)               => 2
  (begin
   (define x 23)
   x)                               => 23

=cut

CLASS->add_inliner('begin',
    via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs, Str :$name!, :$error_cb!, :$optimize_tailcalls) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        return $env->build_scope_with_definitions(CompiledScope,
            $compiler,
            $exprs,
            [],
            compile_params => {
                allow_definitions   => 1,
                optimize_tailcalls  => $optimize_tailcalls,
            },
        );
    },
);

__PACKAGE__->meta->make_immutable;

1;
