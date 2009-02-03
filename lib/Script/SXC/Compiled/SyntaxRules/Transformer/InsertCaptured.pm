package Script::SXC::Compiled::SyntaxRules::Transformer::InsertCaptured;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use namespace::clean -except => 'meta';

has name => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

method transform_to_tree (Object $transformer, Object $compiler, Object $env, HashRef $captures) {

    return $captures->{ $self->name };
}

with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';

1;
