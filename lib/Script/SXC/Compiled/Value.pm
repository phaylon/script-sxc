package Script::SXC::Compiled::Value;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use overload
    '""'     => 'render',
    fallback => 1;

with 'Script::SXC::TypeHinting';
with 'Script::SXC::SourcePosition';

has content => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

method compile { $self }

method render {
    return $self->content;
};

__PACKAGE__->meta->make_immutable;

1;
