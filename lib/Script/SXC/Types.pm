package Script::SXC::Types;
use MooseX::Types
    -base       => 'MooseX::Types::Moose',
    -declare    => [qw( 
        StringRef
    )];

use namespace::clean -except => 'meta';

subtype StringRef, as ScalarRef, 
    where   { is_Str $_ }, 
    message { 'Not a string reference' };

1;
