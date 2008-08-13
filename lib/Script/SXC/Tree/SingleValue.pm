package Script::SXC::Tree::SingleValue;
use Moose::Role;

use namespace::clean -except => 'meta';

has value => (
    is          => 'rw',
);

1;
