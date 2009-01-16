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
use Data::Dump qw( pp );

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('object?',
    firstclass => sub { 
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('object?', [@_], min => 1);
        Scalar::Util::blessed($_) or return undef for @_;
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
                '(do { Scalar::Util::blessed($_) or return undef for %s; 1 })',
                join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
            ),
        );
    },
);

method build_firstclass_bool_call (Str $name!, Str $bool_method!) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($name, [@_], min => 2, max => 2);
        my ($object, $class) = @_;
        return undef
            unless (
                   (Scalar::Util::blessed($object) or Class::MOP::is_class_loaded($object))
               and $object->can($bool_method)
               and $object->$bool_method($class) 
            );
        return 1;
    },  inline_fc   => 1, 
        runtime_req => ['Validation', '+Scalar::Util', '+Class::MOP'], 
        runtime_lex => { '$bool_method' => $bool_method, '$name' => $name };
}

CLASS->add_procedure('isa?',
    firstclass  => CLASS->build_firstclass_bool_call('isa?', 'isa'),
);

CLASS->add_procedure('can?',
    firstclass  => CLASS->build_firstclass_bool_call('can?', 'can'),
);

CLASS->add_procedure('does?',
    firstclass  => CLASS->build_firstclass_bool_call('does?', 'does'),
);

1;
