package Script::SXC::Exception::UnboundVar;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception::ParseError';

has '+type' => (default => 'unbound-var');

has name => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

method build_default_message {
    return sprintf q{Unbound variable: '%s'}, $self->name;
}

__PACKAGE__->meta->make_immutable;

1;
