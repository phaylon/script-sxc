package Script::SXC::Compiled::SyntaxRules::Transformer::InsertCaptured;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use namespace::clean -except => 'meta';

has name => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

method transform_to_tree (Object $transformer, Object $compiler, Object $env, Object $context, ArrayRef $coordinates) {

    # fetch capture value from context
    my $value = $context->get_capture_value($self->name, $coordinates);
    return unless $value;
    return $value;
}

with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';
with 'Script::SXC::Compiled::SyntaxRules::Transformer::Iteration';

__PACKAGE__->meta->make_immutable;

1;
