package Script::SXC::Library;
use Moose;
use MooseX::ClassAttribute;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( HashRef );

use aliased 'Script::SXC::Library::Item::Procedure';
use aliased 'Script::SXC::Library::Item::Inline';

use namespace::clean -except => 'import';

class_has _items => (
    is          => 'rw',
    isa         => HashRef,
    default     => sub { {} },
);

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
