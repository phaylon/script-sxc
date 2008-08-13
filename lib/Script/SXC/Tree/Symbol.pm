package Script::SXC::Tree::Symbol;
use Moose;

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

1;
