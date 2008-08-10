package Script::SXC::Reader::Source;
use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;

use Script::SXC::Types qw( Int Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

requires qw( 
    next_line
    source_description
    end_of_stream
);

coerce Str, from 'ArrayRef[Str]', 
    via { join $/, @$_ };

coerce 'ArrayRef[Str]', from Str, 
    via { [ split "\n", $_ ] };

has line_number => (
    metaclass   => 'Counter',
    is          => 'rw',
    isa         => Int,
    provides    => {
        'inc'       => 'inc_line_number',
        'dec'       => 'dec_line_number',
        'reset'     => 'reset_line_number',
    },
    required    => 1,
    predicate   => 'has_line_number',
);

has line_content => (
    is          => 'rw',
    isa         => Str,
    builder     => 'next_line',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_line_content',
    predicate   => 'has_line_content',
);

1;
