=head1 NAME

Script::SXC::Library::Core::Conditionals - Core Conditionals

=cut

package Script::SXC::Library::Core::Conditionals;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Conditional', 'CompiledConditional'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 if

Syntax:

  (if <condition> <consequence> <alternative>?)

This syntax element will evaluate condition and then, if true, evaluate
the consequence, or the alternative, if false.

If no alternative is given an undefined value will be returned on false.

Examples:

  (if 23 "yes" "no")                => "yes"
  (if 0  "yes" "no")                => "no"
  (if 0  "yes")                     => undef

=cut

for my $cond_name (qw( if unless )) {
    CLASS->add_inliner($cond_name,
        via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls, Str :$name!, :$error_cb!) {
            CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 3);

            # TODO check args, throw exceptions
            my ($cnd, $csq, $alt) = @$exprs;

            return CompiledConditional->new(
                mode        => $cond_name,
                condition   => $cnd->compile($compiler, $env),
                consequence => $csq->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls),
               ( $alt ? (alternative => $alt->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls)) : () ),
            );
        },
    );
}

1;
