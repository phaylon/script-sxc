package Script::SXC::Library::Item::Inline;
use Moose;

use namespace::clean -except => 'meta';

with 'Script::SXC::Library::Item::Inlining';

has '+inliner' => (required => 1);

1;
