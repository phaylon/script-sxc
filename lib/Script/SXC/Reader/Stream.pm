package Script::SXC::Reader::Stream;
use Moose;

use Script::SXC::Reader::Types qw( SourceObject );

use aliased 'Script::SXC::Reader::Source::String', 'StringSourceClass';

use namespace::clean -except => 'meta';

has source => (
    is          => 'rw',
    isa         => SourceObject,
    coerce      => 1,
    required    => 1,
);

1;
