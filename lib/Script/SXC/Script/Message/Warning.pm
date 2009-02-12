package Script::SXC::Script::Message::Warning;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Script::Message';

method default_prefix { 'Warning' }

__PACKAGE__->meta->make_immutable;

1;
