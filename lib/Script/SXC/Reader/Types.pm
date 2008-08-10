package Script::SXC::Reader::Types;
use MooseX::Types
    -base       => 'Script::SXC::Types',
    -declare    => [qw( 
        SourceObject
    )];

use namespace::clean -except => 'meta';

subtype SourceObject, as Object, 
    where   { $_->does('Script::SXC::Reader::Source') },
    message { 'Not a valid Source object' };

1;
