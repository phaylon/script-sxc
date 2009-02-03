package Script::SXC::Compiled::SyntaxRules::Pattern::Hash;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::SyntaxRules::Pattern::List';

has '+alternate_reftype' => (default => 'HASH');

1;
