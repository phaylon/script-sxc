package Script::SXC::Runtime::Validation;
use strict;
use warnings;

use Script::SXC::lazyload
    'Script::SXC::Exception::ArgumentError';

use Scalar::Util qw( blessed );

use namespace::clean -except => 'meta';

sub runtime_arg_count_assertion {
    my ($class, $name, $args, %opt) = @_;
    my ($min, $max)         = @opt{qw( min max )};

    my $got = scalar @$args;

    ArgumentError->throw_to_caller(
        type        => 'missing_arguments',
        message     => "Missing arguments: $name expects at least $min arguments (got $got)",
        up          => 3,
    ) if defined $min and $got < $min;

    ArgumentError->throw_to_caller(
        type        => 'too_many_arguments',
        message     => "Too many arguments: $name expects at most $max arguments (got $got)",
        up          => 3,
    ) if defined $max and $got > $max;
}

my %InternalRuntimeType = (
    'string'        => sub { not ref $_[0] and defined $_[0] },
    'object'        => sub { blessed $_[0] and not $_[0]->isa('Script::SXC::Runtime::Object') },
    'keyword'       => sub { blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Keyword') },
    'symbol'        => sub { blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Symbol') },
    'list'          => sub { (ref $_[0] and ref $_[0] eq 'ARRAY') or (blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Range')) },
    'hash'          => sub { ref $_[0] and ref $_[0] eq 'HASH' },
    'code'          => sub { ref $_[0] and ref $_[0] eq 'CODE' },
    'regex'         => sub { ref $_[0] and ref $_[0] eq 'Regexp' },
    'defined'       => sub { defined $_[0] },
);

sub runtime_type_assertion {
    my ($class, $value, $type, $message) = @_;

    unless ($InternalRuntimeType{ $type }->($value)) {
        ArgumentError->throw_to_caller(
            type    => 'invalid_argument_type',
            message => $message,
            up      => 3,
        );
    }
}

1;
