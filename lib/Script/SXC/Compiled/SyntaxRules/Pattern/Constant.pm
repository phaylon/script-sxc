package Script::SXC::Compiled::SyntaxRules::Pattern::Constant;
use 5.010;
use Moose;
use MooseX::Types::Moose    qw( Str Value );
use MooseX::Method::Signatures;

use Data::Dump qw( pp );

use namespace::clean -except => 'meta';

has constant_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has value => (
    is          => 'rw',
    isa         => Value,
    required    => 1,
);

method match ($item, Object $context) {

    # only matches if it is the same kind of constant with the same value
    return( 
            ref($item) eq $self->constant_class 
        and $item->value eq $self->value 
    );
}

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $constant, Object $sr, Object $pattern, Int $greed_level) {

    # build a new constant placeholder
    return $class->new(
        constant_class  => ref($constant),
        value           => $constant->value,
    );
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

has '+allow_greedy' => (default => 0);

1;
