package Script::SXC::Library::Item::Inlining;
use Moose::Role;

use Script::SXC::Types qw( Method );

use namespace::clean -except => 'meta';

has inliner => (
    is          => 'ro',
    isa         => Method,
);

1;
