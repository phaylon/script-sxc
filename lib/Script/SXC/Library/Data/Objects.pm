package Script::SXC::Library::Data::Objects;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime::Validation;
use Script::SXC::lazyload
    'Script::SXC::Exception::ArgumentError',
    'Script::SXC::Compiler::Environment::Variable',
    [qw( Script::SXC::Compiled::Value   CompiledValue )];

use Scalar::Util;
use List::MoreUtils;
use Data::Dump qw( pp );

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('object?',
    firstclass => sub { 
        # TODO exclude kw/sym objects (runtime objects)
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('object?', [@_], min => 1);
        (Scalar::Util::blessed($_) and not($_->isa('Script::SXC::Runtime::Object'))) or return undef 
            for @_;
        return 1;
    },
    inline_fc => 1,
    runtime_req => ['Validation', '+Scalar::Util'],
    inliner => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        $compiler->add_required_package('Scalar::Util');
        return CompiledValue->new(
            typehint => 'bool',
            content  => sprintf(
                '(do { (Scalar::Util::blessed($_) and not($_->isa(%s))) or return undef for %s; 1 })',
                pp('Script::SXC::Runtime::Object'),
                join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
            ),
        );
    },
);

method build_firstclass_bool_call (Str $name!, Str $bool_method!, Int :$max?) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($name, [@_], min => 2, ($max ? (max => $max) : ()));
        my ($object, @values) = @_;
        return(
            ( List::MoreUtils::all {
                ( ( Scalar::Util::blessed($object) && not($object->isa('Script::SXC::Runtime::Object')) ) 
                  || Class::MOP::is_class_loaded($object) )
                && $object->can($bool_method)
                && $object->can($bool_method)->($object, $_)
              } @values 
            ) ? 1 : undef,
        );
    },  inline_fc   => 1, 
        runtime_req => ['Validation', '+Scalar::Util', '+Class::MOP', '+List::MoreUtils'], 
        runtime_lex => { '$bool_method' => $bool_method, '$name' => $name, '$max' => $max };
}

method build_inline_bool_call (Str $bool_method!, Bool :$string_args?, Int :$max?) {
    return method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, ($max ? (max => $max) : ()));
        $compiler->add_required_package($_)
            for qw( Scalar::Util Class::MOP List::MoreUtils );

        my ($object, @values) = @$exprs;
        my $object_var       = Variable->new_anonymous($bool_method . '_value');

        return CompiledValue->new(
            typehint => 'bool',
            content  => sprintf(
                '(do { my %s = %s; %s })',
                $object_var->render,
                $object->compile($compiler, $env)->render,
                sprintf(
                    '( %s ? 1 : undef )',
                    sprintf(
                        '(List::MoreUtils::all { %s %s and %s->%s($_) } (%s))',
                        sprintf(
                            '( (Scalar::Util::blessed(%s) and not(%s)) or Class::MOP::is_class_loaded(%s))',
                            $object_var->render,
                            sprintf(
                                '%s->isa(%s)',
                                $object_var->render,
                                pp('Script::SXC::Runtime::Object'),
                            ),
                            $object_var->render,
                        ),
                        ( $bool_method eq 'can'
                          ? ''
                          : sprintf(
                                'and %s->can(%s)',
                                $object_var->render,
                                pp($bool_method),
                            ),
                        ),
                        $object_var->render,
                        $bool_method,
                        join ', ', map { $_->compile($compiler, $env, ($string_args ? (to_string => 1) : ()))->render } @values,
                    ),
                ),
            ),
        );
    }
}

CLASS->add_procedure('isa?',
    firstclass  => CLASS->build_firstclass_bool_call('isa?', 'isa', max => 2),
    inliner     => CLASS->build_inline_bool_call('isa', string_args => 1, max => 2),
);

CLASS->add_procedure('can?',
    firstclass  => CLASS->build_firstclass_bool_call('can?', 'can'),
    inliner     => CLASS->build_inline_bool_call('can', string_args => 1),
);

CLASS->add_procedure('does?',
    firstclass  => CLASS->build_firstclass_bool_call('does?', 'does'),
    inliner     => CLASS->build_inline_bool_call('does', string_args => 1),
);

__PACKAGE__->meta->make_immutable;

1;
