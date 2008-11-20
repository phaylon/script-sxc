package Script::SXC::Types;
use MooseX::Types
    -base       => 'MooseX::Types::Moose',
    -declare    => [qw(
        Str
        ScalarRef
        Object
        CodeRef
        HashRef
        Int
        Num
        Bool
        ArrayRef
        Undef

        StringRef
        MooseObject
        TokenObject
        Method
        TypeHint
    )];

use namespace::clean -except => 'meta';

# aliases
# FIXME correct these in source
subtype Str,        as 'Str';
subtype ScalarRef,  as 'ScalarRef';
subtype Object,     as 'Object';
subtype CodeRef,    as 'CodeRef';
subtype HashRef,    as 'HashRef';
subtype Int,        as 'Int';
subtype Num,        as 'Num';
subtype Bool,       as 'Bool';
subtype ArrayRef,   as 'ArrayRef';
subtype Undef,      as 'Undef';

subtype StringRef, as ScalarRef, 
    where   { is_Str $_ }, 
    message { 'Not a string reference' };

subtype MooseObject, as Object, 
    where   { $_->isa('Moose::Object') },
    message { 'Not a Moose object' };

subtype TokenObject, as MooseObject,
    where   { $_->does('Script::SXC::Token') },
    message { 'Not a valid Token object' };

type Method,
    where   { is_CodeRef $_ or (is_Object $_ and $_->isa('Moose::Meta::Method')) },
    message { 'Not a valid method' };

subtype 'Method', as Method, where { 1 };

1;
