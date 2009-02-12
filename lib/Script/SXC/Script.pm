package Script::SXC::Script;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'MooseX::App::Cmd';

__PACKAGE__->meta->make_immutable;

1;
