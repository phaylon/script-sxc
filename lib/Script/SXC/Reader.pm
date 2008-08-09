package Script::SXC::Reader;
use Moose;
use Carp    qw( croak );

use Script::SXC::Types qw( Str HashRef );

use aliased 'Script::SXC::Reader::Stream',          'StreamClass';

use namespace::clean -except => 'meta';
use Method::Signatures;

has stream_class => (
    is          => 'rw',
    isa         => Str,
    lazy        => 1,
    default     => sub { StreamClass },
);

method build_stream ($source, $stream_args) {
    croak 'Optional stream arguments must be hash reference if supplied'
        if defined $stream_args and not is_HashRef $stream_args;

    $stream_args ||= {};
    my $stream = StreamClass->new(%$stream_args, source => $source);

    return $stream;
};

1;
