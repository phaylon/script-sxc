package Script::SXC::Tree::String;
use Moose;
use MooseX::Method::Signatures;

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Constant';
with 'Script::SXC::TypeHinting';

method append_value (Str $value) {
    $self->value($self->value . $value);
    return $self->value;
};

method build_default_typehint { 'string' }

__PACKAGE__->meta->make_immutable;

1;
