package Script::SXC::Library::Item::Inline;
use Moose;

use Script::SXC::Types qw( CodeRef HashRef Str Method );

use namespace::clean -except => 'meta';

has inliner => (
    is          => 'ro',
    isa         => Method,
    required    => 1,
);

__PACKAGE__->meta->make_immutable;

1;
