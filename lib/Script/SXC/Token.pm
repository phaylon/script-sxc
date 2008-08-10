package Script::SXC::Token;
use Moose::Role;

use Script::SXC::Types qw( Int Str );

use namespace::clean -except => 'meta';

requires qw(
    match
);

has value => (
    is          => 'rw',
    required    => 1,
);

has line_number => (
    is          => 'rw',
    isa         => Int,
);

has source_description => (
    is          => 'rw',
    isa         => Str,
);

around match => sub {
    my $next = shift;
    my $self = shift;

    my $match = $self->$next(@_)
        or return undef;

    my $stream = shift;
    do { 
        $_->line_number($stream->source_line_number);
        $_->source_description($stream->source_description);
    } for @$match;

    return $match;
};

1;
