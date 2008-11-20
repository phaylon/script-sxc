package Script::SXC::Tree::Symbol;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

method compile (Object $compiler, Object $env) {

    # find var in environment
    return $env->find_variable($self);
}

__PACKAGE__->meta->make_immutable;

1;
