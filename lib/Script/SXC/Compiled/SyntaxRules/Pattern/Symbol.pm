package Script::SXC::Compiled::SyntaxRules::Pattern::Symbol;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Object Str );

use Script::SXC::lazyload
    'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Capture',
    'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Literal';

use Carp            qw( croak );
use List::MoreUtils qw( any );
use signatures;

use CLASS;
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

method new_from_uncompiled (Object $compiler, Object $env, Object $symbol, Object $sr, Object $pattern, Int $greed_level) {

    # this is a literal symbol
    if (any { $symbol eq $_ } @{ $sr->literals }, '.') {
        return Literal->new(value => $symbol->value);
    }

    # everything else is a capture, but can only be used once
    if ($pattern->has_capture($symbol->value)) {
        $symbol->throw_parse_error(
            'invalid_syntax_capture',
            sprintf "Capture '%s' in syntax-rules can only be used once", $symbol->value,
        );
    }

    # store capture meta information in pattern
    my $capture = Capture->new(value => $symbol->value);
    $pattern->add_capture($symbol);
    $pattern->set_capture_object($symbol->value, $capture);

    return $capture;
}

1;
