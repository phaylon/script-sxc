package Script::SXC::Tree::Number;
use Moose;
use MooseX::Method::Signatures;

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Constant';

__PACKAGE__->meta->make_immutable;

1;
