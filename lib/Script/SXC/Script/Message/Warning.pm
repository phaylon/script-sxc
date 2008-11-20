package Script::SXC::Script::Message::Warning;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Script::Message';

method default_prefix { 'Warning' }

1;
