package Script::SXC::Exception::ArgumentError;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception';

__PACKAGE__->meta->make_immutable;

1;
