package Script::SXC::Library;
use Moose;
use MooseX::ClassAttribute;
use MooseX::Method::Signatures;

use Scalar::Util qw( blessed );

use Script::SXC::Types qw( HashRef );

use aliased 'Script::SXC::Library::Item::Procedure';
use aliased 'Script::SXC::Library::Item::Inline';
use aliased 'Script::SXC::Exception::ArgumentError';

use namespace::clean -except => 'import';

class_has _items => (
    is          => 'rw',
    isa         => HashRef,
    default     => sub { {} },
);

method check_arg_count ($cb!, Str $name!, ArrayRef $exprs!, Int :$min?, Int :$max?) {

    # missing arguments
    $cb->('missing_arguments', 
        message => sprintf('Invalid argument count (missing arguments): %s expects at least %d argument%s (got %d)',
            $name, $min, (($min == 1) ? '' : 's'), scalar(@$exprs)),
    ) if defined $min and @$exprs < $min;

    # too many arguments
    $cb->('too_many_arguments', 
        message => sprintf('Invalid argument count (too many arguments): %s expects at most %d argument%s (got %d)',
            $name, $max, (($max == 1) ? '' : 's'), scalar(@$exprs)),
    ) if defined $max and @$exprs > $max;
}

method runtime_arg_count_assertion ($name!, $args!, :$min, :$max) {
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
    'object'        => sub { blessed $_[0] },
    'keyword'       => sub { blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Keyword') },
    'symbol'        => sub { blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Symbol') },
    'list'          => sub { ref $_[0] and ref $_[0] eq 'ARRAY' },
    'hash'          => sub { ref $_[0] and ref $_[0] eq 'HASH' },
    'code'          => sub { ref $_[0] and ref $_[0] eq 'CODE' },
    'defined'       => sub { defined $_[0] },
);

method runtime_type_assertion ($value!, $type!, $message!) {
    unless ($InternalRuntimeType{ $type }->($value)) {
        ArgumentError->throw_to_caller(
            type    => 'invalid_argument_type',
            message => $message,
            up      => 3,
        );
    }
}

method undef_when_empty (Str $body!) {
    return length($body) ? $body : 'undef';
}

method other_library ($class: Str $library!) {
    Class::MOP::load_class($library);
    return $library;
}

method call_in_other_library($class: Str $library!, Str $proc!, ArrayRef $args = []) {
    return $class->other_library($library)->get($proc)->firstclass->(@$args);
};

method add ($class: $name!, Object $item!) {
    $class->_items->{ $_ } = $item
        for ref($name) ? @$name : $name;
    return $item;
};

method get (Str $name!) {
#    warn "GETTING $name\n";
    my $x = $self->_items->{ $name };
#    warn "VALUE $x\n";
    return $x;
};

method add_procedure ($class: $name!, Method :$firstclass!, Method :$inliner) {
    my $proc = Procedure->new(
        firstclass  => $firstclass,
        ($inliner ? (inliner => $inliner) : ()),
        library     => $class,
        name        => (ref($name) ? $name->[0] : $name),
    );
    return $class->add($name, $proc);
};

method add_inliner ($class: $name!, :$via!) {
    my $inliner = Inline->new(
        inliner     => $via,
    );
    return $class->add($name, $inliner);
};

__PACKAGE__->meta->make_immutable;

1;
