package Script::SXC::Exception::UnboundVar;
use Moose;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception::ParseError';

has '+type' => (default => 'unbound-var');

__PACKAGE__->meta->make_immutable;

1;
