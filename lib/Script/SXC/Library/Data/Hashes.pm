package Script::SXC::Library::Data::Hashes;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Exception::ArgumentError;
use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    [qw( Script::SXC::Compiled::Value       CompiledValue )],
    [qw( Script::SXC::Compiled::TypeCheck   CompiledTypeCheck )];

use CLASS;
use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('hash', 
    firstclass => sub {
        Script::SXC::Exception::ArgumentError->throw_to_caller(
            type    => 'invalid_argument_list',
            message => "hash constructor expects even size list of key/value pairs",
        ) if @_ % 2;
        return +{ @_ };
    },
    inline_fc => 1,
    runtime_req => ['+Script::SXC::Exception::ArgumentError'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        (@$exprs ? $exprs->[-1] : $symbol)->throw_parse_error(
            invalid_argument_list => "hash constructor expects even sized list of key/value pairs",
        ) if @$exprs % 2;
        return CompiledValue->new(
            content  => sprintf('+{( %s )}', join(', ', map { $_->compile($compiler, $env, to_string => 1)->render } @$exprs)),
            typehint => 'hash',
        );
    },
);

CLASS->add_procedure('values',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('values', [@_], min => 1, max => 1);
        Script::SXC::Runtime::Validation->runtime_type_assertion($_[0], 'hash', 'values expects a hash as argument');
        return [ values %{ $_[0] } ];
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf(
            '[ values %%{ %s } ]',
            CompiledTypeCheck->new(
                expression  => $exprs->[0]->compile($compiler, $env),
                type        => 'hash',
                source_item => $exprs->[0],
                message     => "$name expects a hash as argument",
            )->render,
        ), typehint => 'list');
    },
);

CLASS->add_procedure('keys',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('keys', [@_], min => 1, max => 1);
        Script::SXC::Runtime::Validation->runtime_type_assertion($_[0], 'hash', 'keys expects a hash as argument');
        return [ keys %{ $_[0] } ];
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf(
            '[ keys %%{ %s } ]',
            CompiledTypeCheck->new(
                expression  => $exprs->[0]->compile($compiler, $env),
                type        => 'hash',
                source_item => $exprs->[0],
                message     => "$name expects a hash as argument",
            )->render,
        ), typehint => 'list');
    },
);

CLASS->add_procedure('hash-ref',
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('hash-ref', [@_], min => 2, max => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion($_[0], 'hash', 'hash-ref expects a hash as first argument');
        return $_[0]->{ $_[1] };
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    setter => sub ($compiler, $env, $args, $expr, $symbol) {
        $symbol->throw_parse_error(missing_setter_args => "Missing arguments: hash-ref setter needs list and index arguments")
            if @$args < 2;
        $args->[2]->throw_parse_error(too_many_setter_args => "Too many arguments for hash-ref setter")
            if @$args > 2;
        my ($hash, $key) = @$args;
        my $compiled_expr = $expr->compile($compiler, $env);
        return CompiledValue->new(content => sprintf(
            '( (%s)->{ %s } = %s )',
            CompiledTypeCheck->new(
                expression  => $hash->compile($compiler, $env),
                type        => 'hash',
                source_item => $symbol,
                message     => "hash-ref setter needs a hash as first and a key as second argument",
            )->render,
            $key->compile($compiler, $env, to_string => 1)->render,
            $compiled_expr->render,
        ), $compiled_expr->can('typehint') ? (typehint => $compiled_expr->typehint) : ());
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs, :$name, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);

        return CompiledValue->new(
            content => sprintf('( (%s)->{%s} )', 
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'hash',
                    source_item => $exprs->[0],
                    message     => 'first argument to hash-ref must be a hash',
                )->render,
                $exprs->[1]->compile($compiler, $env, to_string => 1)->render,
            ),
        );
    },
);

CLASS->add_procedure('merge',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('merge', [@_], min => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion(
            $_[ $_ ], 'hash', "Invalid argument $_: merge expects only hash arguments")
          for 0 .. $#_;
        return +{ map { (%$_) } @_ };
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        return CompiledValue->new(content => sprintf(
            '(+{( %s )})',
            join(', ', map {
                sprintf '(%%{( %s )})', CompiledTypeCheck->new(
                    expression  => $exprs->[ $_ ]->compile($compiler, $env),
                    type        => 'hash',
                    source_item => $exprs->[ $_ ],
                    message     => "Invalid argument $_: $name expects only hash arguments",
                )->render,
            } 0 .. $#$exprs),
        ), typehint => 'hash');
    },
);

CLASS->add_procedure('hash?',
    firstclass  => CLASS->build_firstclass_reftest_operator('hash?', 'HASH'),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_reftest_operator('HASH'),
);

__PACKAGE__->meta->make_immutable;

1;
