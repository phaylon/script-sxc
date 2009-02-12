package Script::SXC::Compiled::Validation::Where;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

method render_test { $self->render_expression }

method render_message { sprintf q{Argument '%s' does not pass parameter constraints}, $self->parameter_name }

method build_default_exception_type { 'invalid_argument' }

with 'Script::SXC::Compiled::Validation';

__PACKAGE__->meta->make_immutable;

1;
