package Script::SXC::Compiled::Application::List;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::Application';

__PACKAGE__->meta->make_immutable;

1;
