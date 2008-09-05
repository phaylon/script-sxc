package Script::SXC::Reader::Types;
use MooseX::Types
    -base       => 'Script::SXC::Types',
    -declare    => [qw( 
        SourceObject
    )];

use aliased 'Script::SXC::Reader::Source::String', 'StringSourceClass';
use namespace::clean -except => 'meta';

subtype SourceObject, as Object, 
    where   { $_->does('Script::SXC::Reader::Source') },
    message { 'Not a valid Source object' };

coerce SourceObject, from ScalarRef, 
    via { StringSourceClass->new(lines => $$_) };

1;
