package Script::SXC::SourcePosition;
use Moose::Role;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( Str Int Maybe );

use namespace::clean -except => 'meta';

has line_number => (
    is          => 'rw',
    isa         => Int,
);

has source_description => (
    is          => 'rw',
    isa         => Str,
);

has char_number => (
    is          => 'rw',
    isa         => Maybe[Int],
);

method source_information () {
    return map { ($_ => $self->$_) } 
        qw( line_number source_description char_number );
}

1;
