package Script::SXC::Tree::Constant;
use Moose::Role;
use MooseX::Method::Signatures;

use Data::Dump qw( pp );

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use Scalar::Util qw( blessed );

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

method quoted (Object $compiler!, Object $env!) {

    # build compiled value
    return $self->compile($compiler, $env);
};

with 'Script::SXC::Tree::Quotability';

method compile (Object $compiler, Object $env) {

    # build compiled value
    return CompiledValue->new(
        content => ( blessed($self->value) ? $self->compile_object_value($compiler, $env, $self->value) : pp($self->value) ),
      ( $self->does('Script::SXC::TypeHinting') ? (typehint => $self->typehint) : () ),
    );
};

method compile_object_value (Object $object) {
    return pp($object);
}

1;
