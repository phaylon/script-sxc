package Script::SXC::Compiled::SyntaxTransform;
use Moose::Role;

use namespace::clean -except => 'meta';

with 'Script::SXC::SourcePosition';
with 'Script::SXC::Library::Item::Inlining';

1;
