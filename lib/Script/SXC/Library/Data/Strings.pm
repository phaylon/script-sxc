package Script::SXC::Library::Data::Strings;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    [qw( Script::SXC::Compiled::TypeCheck   CompiledTypeCheck )],
    [qw( Script::SXC::Compiled::Value       CompiledValue )];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('string',
    firstclass => sub { join '', @_ },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        return CompiledValue->new(content => sprintf(
            'join("", %s)',
            join(', ', map { $_->compile($compiler, $env, to_string => 1)->render } @$exprs),
        ), typehint => 'string')
    },
);

CLASS->add_procedure('string?',
    firstclass => sub { 
        CLASS->runtime_arg_count_assertion('string?', [@_], min => 1);
        for (@_) { 
            defined and not ref or return undef;
        };
        return 1;
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        my $var = Variable->new_anonymous('string_test');
        # TODO: optimize var-expr case, optimize $var rendering
        return CompiledValue->new(content => sprintf
            '( (%s) ? 1 : undef )',
            join ' and ',
            map {
                sprintf 'do { my %s = %s; defined(%s) and not ref(%s) }',
                    $var->render,
                    $_->compile($compiler, $env)->render,
                    $var->render,
                    $var->render,
            }
            @$exprs,
        );
    },
);

CLASS->add_procedure('eq?',
    firstclass  => CLASS->build_firstclass_equality_operator('eq?', sub { $_[0] eq $_[1] }),
    inliner     => CLASS->build_inline_equality_operator('eq?', perl_operator => 'eq', to_string => 1),
);

CLASS->add_procedure('ne?',
    firstclass  => CLASS->build_firstclass_nonequality_operator('ne?', sub { $_[0] ne $_[1] }),
    inliner     => CLASS->build_inline_nonequality_operator('ne?', perl_operator => 'ne', to_string => 1),
);

CLASS->add_procedure('gt?',
    firstclass  => CLASS->build_firstclass_sequence_operator('gt?', sub { $_[0] gt $_[1] }),
    inliner     => CLASS->build_inline_sequence_operator('gt?', perl_operator => 'gt', to_string => 1),
);

CLASS->add_procedure('lt?',
    firstclass  => CLASS->build_firstclass_sequence_operator('lt?', sub { $_[0] lt $_[1] }),
    inliner     => CLASS->build_inline_sequence_operator('lt?', perl_operator => 'lt', to_string => 1),
);

CLASS->add_procedure('ge?',
    firstclass  => CLASS->build_firstclass_sequence_operator('ge?', sub { $_[0] ge $_[1] }),
    inliner     => CLASS->build_inline_sequence_operator('ge?', perl_operator => 'ge', to_string => 1),
);

CLASS->add_procedure('le?',
    firstclass  => CLASS->build_firstclass_sequence_operator('le?', sub { $_[0] le $_[1] }),
    inliner     => CLASS->build_inline_sequence_operator('le?', perl_operator => 'le', to_string => 1),
);

CLASS->add_procedure('join',
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('join', [@_], min => 2, max => 2);
        CLASS->runtime_type_assertion($_[1], 'list', 'join expects a list as second argument');
        my ($sep, $ls) = @_;
        return join $sep, @$ls;
    },
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        my ($sep, $ls) = @$exprs;
        return CompiledValue->new(content => sprintf 'join(%s, (@{( %s )}))',
            $sep->compile($compiler, $env, to_string => 1)->render,
            CompiledTypeCheck->new(
                expression  => $ls->compile($compiler, $env),
                type        => 'list',
                source_item => $ls,
                message     => "$name expects a list as second argument",
            )->render,
        );
    },
);

1;
