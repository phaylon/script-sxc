package Script::SXC::CompileToSelf;
use Moose::Role;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

method compile { $self }

1;
