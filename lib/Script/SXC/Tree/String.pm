package Script::SXC::Tree::String;
use Moose;
use MooseX::Method::Signatures;

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Constant';

method append_value (Str $value) {
    $self->value($self->value . $value);
    return $self->value;
};

__PACKAGE__->meta->make_immutable;

1;
