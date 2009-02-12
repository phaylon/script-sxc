package Script::SXC::Library::Data::Code;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime;
use Script::SXC::Runtime::Validation;
use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    [qw( Script::SXC::Compiled::Value   CompiledValue )];

use CLASS;
use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('code?',
    firstclass  => CLASS->build_firstclass_reftest_operator('code?', 'CODE'),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_reftest_operator('CODE'),
);

method build_firstclass_curry ($lib: Str $name!, CodeRef $arg_builder!) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($name, [@_], min => 2);
        my ($invocant, @args)  = @_;
        return sub {
            @_ = ($invocant, [$arg_builder->([@args], [@_])]);
            goto \&Script::SXC::Runtime::apply;
        };
    }, runtime_req => ['Validation', '+'], runtime_lex => { '$name' => $name, '$arg_builder' => $arg_builder };
}

method build_inline_curry ($lib: CodeRef $arg_builder!) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!, Object :$symbol!) {
        $lib->check_arg_count($error_cb, $name, $exprs, min => 2);
        my $args = Variable->new_anonymous('curry_args', $symbol->source_information);
        my ($invocant, @end_args) = @$exprs;
        return $symbol->new_item_with_source('List', {
            contents => [
                $symbol->new_item_with_source('Builtin', { value => 'lambda' }),
                $args,
                $symbol->new_item_with_source('List', {
                    contents => [
                        $symbol->new_item_with_source('Builtin', { value => 'apply' }),
                        $arg_builder->($invocant, [@end_args], $args, $symbol),
                    ],
                }),
            ],
        })->compile($compiler, $env);
    },
}

CLASS->add_procedure('curry',
    firstclass  => CLASS->build_firstclass_curry('curry', sub ($orig, $rest) { (@$orig, @$rest) }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_curry(sub ($inv, $orig, $rest, $sym) { ($inv, @$orig, $rest) }),
);

#
#   (apply ...)
#          inv (quasiquote ((unquote-splicing $rest)
#

CLASS->add_procedure('rcurry',
    firstclass  => CLASS->build_firstclass_curry('rcurry', sub ($orig, $rest) { (@{ $rest }, @{ $orig }) }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_curry(sub ($inv, $orig, $rest, $sym) {
        return(
            $inv,
            $sym->new_item_with_source('List', {
                contents => [
                    $sym->new_item_with_source('Builtin', { value => 'quasiquote' }),
                    $sym->new_item_with_source('List', {
                        contents => [
                            $sym->new_item_with_source('List', {
                                contents => [
                                    $sym->new_item_with_source('Builtin', { value => 'unquote-splicing' }),
                                    $rest,
                                ],
                            }),
                            map {
                                $sym->new_item_with_source('List', {
                                    contents => [
                                        $sym->new_item_with_source('Builtin', { value => 'unquote' }),
                                        $_,
                                    ],
                                });
                            } @$orig,
                        ],
                    }),
                ],
            }),
        );
    }),
);

__PACKAGE__->meta->make_immutable;

1;
