package Script::SXC::Compiled::Goto;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::Application';

method render_code_application (Object $invocant!, Str $args!) {
    return sprintf '(do { @_ = (%s); goto %s })', $args, $invocant->render;
}

__PACKAGE__->meta->make_immutable;

1;
