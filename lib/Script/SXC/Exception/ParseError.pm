package Script::SXC::Exception::ParseError;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception';

has type => (
    is          => 'rw',
    isa         => Str,
);

__PACKAGE__->meta->make_immutable;

1;
