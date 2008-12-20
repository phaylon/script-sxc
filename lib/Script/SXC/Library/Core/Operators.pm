=head1 NAME

Script::SXC::Library::Core::Operators - Core Operators

=cut

package Script::SXC::Library::Core::Operators;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 or

C<or> will evaluate every one of its arguments and return the first
true value or the last false value if none are true. When called without
any arguments, it compiles to the undefined value

Examples:

  (or 2 3 4)            => 4
  (or 0 1 2)            => 1
  (or -1 0 1)           => -1
  (or "" 0)             => 0
  (or)                  => undef

=cut

CLASS->add_inliner('or',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls, :$error_cb!, Str :$name!) {
        return CompiledValue->new(
            content => sprintf '(%s)', 
                CLASS->undef_when_empty(join(' or ', 
                    map  { $_->render } 
                    @{ $compiler->compile_optimized_sequence($env, $exprs, optimize_tailcalls => $optimize_tailcalls) },
                )),
        );
    },
);

=head2 and

Just like C<or>, C<and> will evaluate every argument in turn. But it will
return the last true value if all are true, or the first false value it 
encounters.

Examples:

  (and 2 3 4)           => 4
  (and 2 0 3)           => 0
  (and "" 0)            => ""
  (and)                 => undef

=cut

CLASS->add_inliner('and',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls) {
        return CompiledValue->new(
            content => sprintf '(%s)', 
                CLASS->undef_when_empty(join(' and ', 
                    map  { $_->render } 
                    @{ $compiler->compile_optimized_sequence($env, $exprs, optimize_tailcalls => $optimize_tailcalls) },
                )),
        );
    },
);

=head2 err

This has the same functionality as C<or>, but it tests on definedness
rather than truth.

Examples:

  (err 1 2 3)           => 1
  (err #f "" 3)         => ""
  (err #f #f)           => undef
  (err)                 => undef

=cut

CLASS->add_inliner('err', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb, :$name) {

    return CompiledValue->new(content => sprintf '(%s)', CLASS->undef_when_empty(
        join ' // ', map { $_->compile($compiler, $env)->render } @$exprs,
    ));
});

=head2 def

This is kind of like C<and>, and will return a true value when all its arguments
are defined, and a false value if one or more are undefined. When called without
arguments, it will return an undefined value.

The main difference between this and the other operators is that this will not
return one of the values, but only true or false.

Examples:

  (def 3 4)             => true
  (def 3 #f 5)          => false
  (def)                 => undef

=cut

CLASS->add_inliner('def', via => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb, :$name) {

    return CompiledValue->new(content => sprintf '(%s)', CLASS->undef_when_empty(
        join ' and ', map { sprintf 'defined(%s)', $_->compile($compiler, $env)->render } @$exprs,
    ));
});

=head2 not

The C<not> operator will return true if all of its arguments are false, and
false if one or more of them are true. It will return an undefined value when
called without arguments.

Examples:

  (not #f "" 0)             => true
  (not 1 0)                 => false
  (not)                     => undef

=cut

CLASS->add_inliner('not',
    via => method (Object :$compiler, Object :$env, ArrayRef :$exprs) {
        return CompiledValue->new(
            content => sprintf  '(%s)', 
                CLASS->undef_when_empty(join(' and ', 
                    map  { sprintf 'not(%s)', $_->compile($compiler, $env)->render }
                    @{ $exprs },
                )),
        );
    },
);

=head2 ~~

=cut

CLASS->add_procedure('~~',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('~~', [@_], min => 2, max => 2);
        return( $_[0] ~~ $_[1] ? 1 : undef );
    },
    inliner => method (:$compiler!, :$env!, :$name!, :$exprs!, :$error_cb!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        return CompiledValue->new(content => sprintf 
            '( (%s ~~ %s) ? 1 : undef )',
            map { $_->compile($compiler, $env) } @$exprs,
        );
    },
);

=head1 SEE ALSO

=cut

1;
