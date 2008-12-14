package Script::SXC::Compiler::Environment::Variable;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str Object Int );

use aliased 'Script::SXC::Compiler::Environment::Variable::Outer';

use namespace::clean -except => 'meta';

with 'Script::SXC::TypeHinting';

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

method compile { $self }

method as_outer {
    return Outer->new(%$self);
}

method new_anonymous ($class: Str $info?) {
    $info = '' unless defined $info;

    # prepare identifier
    my $id = $class->_counted_type('anon') . ($info ? "_$info" : '');

    return $class->new(identifier => $id, symbol_name => "<$id>");
}

method new_from_name ($class: Str $name!, Str :$prefix?) {

    # prefix defaults to 'lex', must be true, not just defined (no 0, '', undef)
    $prefix ||= 'lex';
    
    # prepare cleaned up identifier
    (my $id = sprintf '%s_%s', $class->_counted_type($prefix), $name) 
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
