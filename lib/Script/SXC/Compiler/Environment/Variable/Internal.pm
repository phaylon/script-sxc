package Script::SXC::Compiler::Environment::Variable::Internal;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiler::Environment::Variable';

__PACKAGE__->meta->make_immutable;

1;
