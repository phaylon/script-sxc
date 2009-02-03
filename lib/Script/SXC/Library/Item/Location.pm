package Script::SXC::Library::Item::Location;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use namespace::clean -except => 'meta';

has library => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

has name => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

method library_location () {
    return map { ($_ => $self->$_) }
        qw( library name );
}

1;
