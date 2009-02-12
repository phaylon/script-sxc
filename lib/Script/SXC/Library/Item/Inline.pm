package Script::SXC::Library::Item::Inline;
use Moose;

use namespace::clean -except => 'meta';

with 'Script::SXC::Library::Item::Inlining';
with 'Script::SXC::Library::Item::Location';
with 'Script::SXC::CompileToSelf';

has '+inliner' => (required => 1);

__PACKAGE__->meta->make_immutable;

1;
