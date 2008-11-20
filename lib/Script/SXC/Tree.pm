package Script::SXC::Tree;
use Moose;

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Container';

__PACKAGE__->meta->make_immutable;

1;
