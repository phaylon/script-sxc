package Script::SXC::Runtime::Keyword;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use overload
    '""'     => 'stringify',
    fallback => 1;

has value => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

method stringify () { $self->value };

__PACKAGE__->meta->make_immutable;

1;
