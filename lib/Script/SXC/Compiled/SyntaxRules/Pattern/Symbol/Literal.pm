package Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Literal;
use Moose;
use MooseX::Method::Signatures;

use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use Scalar::Util qw( blessed );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol';

method match ($item, Object $ctx) {

    # literals only match on symbols of the same value
    return undef
        unless blessed $item
           and $item->isa(SymbolClass)
           and $item eq $self->value;

    # we have a match
    return $self;
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

has '+allow_greedy' => (default => 0);

__PACKAGE__->meta->make_immutable;

1;
