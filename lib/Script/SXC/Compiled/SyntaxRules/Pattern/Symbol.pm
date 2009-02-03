package Script::SXC::Compiled::SyntaxRules::Pattern::Symbol;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Object Str );

use Script::SXC::lazyload
    'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Capture',
    'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Literal';

use Carp            qw( croak );
use List::MoreUtils qw( any );

use CLASS;
use signatures;
use namespace::clean -except => 'meta';

has value => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

before new => sub ($class) { 
    croak "base class $class cannot be instantiated directly"
        if $class eq CLASS;
};

method new_from_uncompiled (Object $compiler, Object $env, Object $symbol, Object $sr, Object $pattern) {

    if (any { $symbol eq $_ } @{ $sr->literals }, '.') {
        return Literal->new(value => $symbol->value);
    }

    $pattern->add_capture($symbol);
    return Capture->new(value => $symbol->value);
}

1;
