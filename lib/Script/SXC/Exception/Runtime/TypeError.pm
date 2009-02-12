package Script::SXC::Exception::Runtime::TypeError;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception::Runtime';

__PACKAGE__->meta->make_immutable;

1;
