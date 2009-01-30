=head1 NAME

Script::SXC::Library::Core::Apply - Core Function Application

=cut

package Script::SXC::Library::Core::Apply;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime;
use Script::SXC::lazyload
    [qw( Script::SXC::Compiled::Application     CompiledApply       )],
    [qw( Script::SXC::Compiled::Value           CompiledValue       )],
    [qw( Script::SXC::Compiled::TypeCheck       CompiledTypeCheck   )];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 apply

=cut

CLASS->add_procedure('apply',
    firstclass  => CLASS->build_direct_firstclass('Script::SXC::Runtime', 'apply', min => 2),
    inline_fc   => 1,
    inliner     => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        my ($invocant, @args) = @$exprs;

        my $last_arg = pop @args;

        return CompiledApply->new_from_uncompiled(
            $compiler,
            $env,
            invocant    => $invocant,
            arguments   => [
                @args,
                CompiledValue->new(content => sprintf '(@{( %s )})',
                    CompiledTypeCheck->new(
                        expression  => $last_arg->compile($compiler, $env),
                        type        => 'list',
                        source_item => $last_arg,
                        message     => "Invalid argument type: Last argument to $name must be a list",
                    )->render,
                ),
            ],
            tailcalls                   => $compiler->optimize_tailcalls,
            return_type                 => 'scalar',
            inline_invocant             => 0,
            inline_firstclass_args      => 0,
            ($symbol->can('source_information') ? $symbol->source_information : ()),
            options => {
                optimize_tailcalls  => $compiler->optimize_tailcalls,
                first_class         => $compiler->force_firstclass_procedures,
                source              => $self,
            },
        );
    },
);

CLASS->add_inliner('apply!',
    via => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        my ($var, $apply) = @$exprs;
        return $symbol->new_item_with_source('List', { contents => [
            $symbol->new_item_with_source('Builtin', { value => 'set!' }),
            $var,
            $symbol->new_item_with_source('List', { contents => [
                $apply,
                $var,
            ]}),
        ]})->compile($compiler, $env);
    },
);

1;
