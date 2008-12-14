package Script::SXC::Runtime::Symbol;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Str );

use Scalar::Util qw( refaddr );

use namespace::clean -except => 'meta';
use overload
    '""'     => 'stringify',
    fallback => 1;

has value => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

method stringify { sprintf '<%s (%s) at %s>', ref($self), $self->value, refaddr($self) }

__PACKAGE__->meta->make_immutable;

1;
