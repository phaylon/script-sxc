package Script::SXC::Compiled::SyntaxRules::Pattern::Symbol::Capture;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Bool );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::SyntaxRules::Pattern::Symbol';

method match ($value, Object $ctx, ArrayRef $coordinates) {

    # remember the value we matched
    $ctx->set_capture_value($self->value, $coordinates, $value);
    return 1;
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

1;
