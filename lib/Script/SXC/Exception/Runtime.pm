package Script::SXC::Exception::Runtime;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception';

__PACKAGE__->meta->make_immutable;

1;
