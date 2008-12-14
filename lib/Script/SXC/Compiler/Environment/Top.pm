package Script::SXC::Compiler::Environment::Top;
use Moose;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Undef HashRef );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiler::Environment';

my @DefaultLibraries = 
    map { Class::MOP::load_class($_) and $_ }
    map { "Script::SXC::Library::$_" }
        qw( Core Data );

has '+parent' => (
    isa         => Undef,
    required    => 0,
);

has libraries => (
    metaclass   => 'Collection::Hash',
    is          => 'rw',
    isa         => HashRef,
    required    => 1,
    lazy        => 1,
    builder     => 'build_default_libraries',
    provides    => {
        'keys'      => 'library_classes',
        'values'    => 'library_objects',
        'get'       => 'get_library',
        'set'       => 'set_library',
    },
);

method find_library_item (Str $name!) {
#    $name =~ s/^[a-z]+://;

  LIBRARY:  
    for my $lib ($self->library_objects) {
        #warn "CHECKING LIBRARY $lib FOR $name\n";
        my $item = $lib->get($name)
            or next LIBRARY;
        return $item;
    }

    return undef;
};

method build_default_libraries {
    my %libraries;
    $libraries{ $_ } = $_->new
        for @DefaultLibraries;
    return \%libraries;
};

override has_variable => method (Str $name!) { 
    
    super or $self->find_library_item($name);
};

override get_variable => method (Str $name!) {

    super or $self->find_library_item($name);
};

#override find_env_for_variable => method (Str $name!) {
#    
#    return $self 
#        if $self->find_library_item($name);
#
#    return super;
#};

#override find_variable => method (Str $name!) {
#    warn "LOOKING FOR $name\n";
#    
#    unless ($self->has_variable($name)) {
#        if (my $item = $self->find_library_item($name)) {
#            return $item;
#        }
#    }
#
#    return super;
#};

__PACKAGE__->meta->make_immutable;

1;
