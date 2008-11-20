package Script::SXC::Tree::Boolean;
use Moose;
use MooseX::Method::Signatures;

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

method compile (Object $compiler, Object $env) {
    return CompiledValue->new(content => ($self->value ? 1 : 'undef()'));
};

__PACKAGE__->meta->make_immutable;

1;
