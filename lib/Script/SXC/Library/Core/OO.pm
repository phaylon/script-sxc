package Script::SXC::Library::Core::OO;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->meta->make_immutable;

1;
