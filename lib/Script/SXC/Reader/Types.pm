package Script::SXC::Reader::Types;
use MooseX::Types
    -base       => 'Script::SXC::Types',
    -declare    => [qw( 
        MooseObject
        SourceObject
    )];

use namespace::clean -except => 'meta';

subtype MooseObject, as Object, 
    where   { $_->isa('Moose::Object') },
    message { 'Not a Moose object' };

subtype SourceObject, as Object, 
    where   { $_->does('Script::SXC::Reader::Source') },
    message { 'Not a valid Source object' };

1;
