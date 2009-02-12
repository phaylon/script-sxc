package Script::SXC::Exception::MissingClose;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception::ParseError';

__PACKAGE__->meta->make_immutable;

1;
