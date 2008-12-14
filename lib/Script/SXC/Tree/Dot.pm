package Script::SXC::Tree::Dot;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Tree::Symbol';

method compile {
    $self->throw_parse_error(invalid_dot_symbol => 'The dot symbol is reserved and cannot be used as an identifier');
}

__PACKAGE__->meta->make_immutable;

1;

