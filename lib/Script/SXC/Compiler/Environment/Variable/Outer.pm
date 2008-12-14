package Script::SXC::Compiler::Environment::Variable::Outer;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiler::Environment::Variable';

method typehint         { undef }
method type_might_be    { undef }

method try_typehinting_from {
    $self->original->typehint(undef);
}

1;
