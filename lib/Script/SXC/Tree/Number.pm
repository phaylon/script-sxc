package Script::SXC::Tree::Number;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use Data::Dump qw( pp );

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Constant';

method compile_object_value (Object $compiler, Object $env, Object $object) {

    if ($object->isa('Math::BigRat')) {
        $compiler->add_required_package('Math::BigRat');
        return sprintf '(Math::BigRat->new(%s))', pp("$object");
    }
    else {
        return pp $object;
    }
}

__PACKAGE__->meta->make_immutable;

1;
