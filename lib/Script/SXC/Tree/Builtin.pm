package Script::SXC::Tree::Builtin;
use Moose;

use namespace::clean -except => 'meta';
use Method::Signatures;

extends 'Script::SXC::Tree::Symbol';

__PACKAGE__->meta->make_immutable;

1;
