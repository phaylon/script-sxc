package Script::SXC::Exception::Localized;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script:SXC::Exception';

has original => (
    is          => 'rw',
);

1;
