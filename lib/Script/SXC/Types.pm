package Script::SXC::Types;
use MooseX::Types
    -base       => 'MooseX::Types::Moose',
    -declare    => [qw( 
        StringRef
        MooseObject
        TokenObject
    )];

use namespace::clean -except => 'meta';

subtype StringRef, as ScalarRef, 
    where   { is_Str $_ }, 
    message { 'Not a string reference' };

subtype MooseObject, as Object, 
    where   { $_->isa('Moose::Object') },
    message { 'Not a Moose object' };

subtype TokenObject, as MooseObject,
    where   { $_->does('Script::SXC::Token') },
    message { 'Not a valid Token object' };

1;
