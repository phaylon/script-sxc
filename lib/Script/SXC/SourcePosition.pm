package Script::SXC::SourcePosition;
use Moose::Role;

use Script::SXC::Types qw( Str Int );

use namespace::clean -except => 'meta';

has line_number => (
    is          => 'rw',
    isa         => Int,
);

has source_description => (
    is          => 'rw',
    isa         => Str,
);

1;
