package Script::SXC::Reader::Source;
use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Int Str );

use signatures;
use namespace::clean -except => 'meta';

#requires qw( 
#    next_line
#    source_description
#    end_of_stream
#);

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

has initial_line_length => (
    is          => 'rw',
    isa         => Int,
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

after next_line => sub ($self) {
    $self->initial_line_length($self->has_line_content ? length($self->line_content) : 0);
};

1;
