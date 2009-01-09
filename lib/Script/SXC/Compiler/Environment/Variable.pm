package Script::SXC::Compiler::Environment::Variable;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str Object Int );

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable::Outer',
    'Script::SXC::Compiler::Environment::Variable::Global';

use namespace::clean -except => 'meta';

with 'Script::SXC::TypeHinting';
with 'Script::SXC::SourcePosition';

my $VarCounter = 0;

has identifier => (
    is              => 'ro',
    isa             => Str,
    required        => 1,
);

has symbol_name => (
    is              => 'ro',
    isa             => Str,
);

has sigil => (
    is              => 'ro',
    isa             => Str,
    required        => 1,
    default         => '$',
);

method render {

    # simply return identifier as a perl var
    return $self->sigil . $self->identifier;
}

method render_array_access (Int $index!) {
    return '$' . $self->identifier . '[' . $index . ']';
}

method compile { $self }

method as_outer {
    return Outer->new(%$self, original => $self);
}

method new_anonymous ($class: Str $info?, Str :$sigil?, :$line_number?, :$source_description?) {
    $info = ''
        unless defined $info;

    # prepare identifier
    my $id = $class->_counted_type('anon') . ($info ? "_$info" : '');

    return $class->new(
        identifier  => $id,
        symbol_name => "<$id>",
        ( defined($line_number)         ? (line_number => $line_number)                 : () ),
        ( defined($source_description)  ? (source_description => $source_description)   : () ),
        ( defined($sigil)               ? (sigil => $sigil)                             : () ),
    );
}

method new_perl_global ($class: Str $name!, Str $sigil!, Str :$typehint?) {

    return Global->new(identifier => $name, sigil => $sigil, typehint => $typehint);
}

method new_from_name ($class: Str $name!, Str :$prefix?) {

    # prefix defaults to 'lex', must be true, not just defined (no 0, '', undef)
    $prefix ||= 'lex';

    my $internal_name = $name eq '_' ? 'topic' : $name;
    
    # prepare cleaned up identifier
    (my $id = sprintf '%s_%s', $class->_counted_type($prefix), $internal_name) 
        =~ s/[^a-z0-9_]+//gi;

    return $class->new(identifier => $id, symbol_name => $name);
}

my %VarCounter;

method _counted_type (Str $type!) {

    # build combined type/count id
    return $type . $VarCounter{ $type }++;
}

__PACKAGE__->meta->make_immutable;

1;
