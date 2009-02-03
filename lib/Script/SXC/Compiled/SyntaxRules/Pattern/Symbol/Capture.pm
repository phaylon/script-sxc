package Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Capture;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol';

method match ($value, HashRef $captures) {

    $captures->{ $self->value } = $value;
#    say 'capture ', $self->value, ' with value ', $value;
    return 1;
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

1;
