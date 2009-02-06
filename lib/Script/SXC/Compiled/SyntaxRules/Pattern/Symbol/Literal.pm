package Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Literal;
use Moose;
use MooseX::Method::Signatures;

use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use Scalar::Util qw( blessed );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol';

method match ($item, Object $ctx) {

    return undef
        unless blessed $item
           and $item->isa(SymbolClass)
           and $item eq $self->value;

    return $self;
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

1;
