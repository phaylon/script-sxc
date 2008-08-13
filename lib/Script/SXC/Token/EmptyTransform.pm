package Script::SXC::Token::EmptyTransform;
use Moose::Role;

use namespace::clean -except => 'meta';
use Method::Signatures;

method transform { return };

1;
