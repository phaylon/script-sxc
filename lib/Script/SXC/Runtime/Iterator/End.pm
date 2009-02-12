package Script::SXC::Runtime::Iterator::End;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

method singleton { 
    state $singleton = $self->new;
}

__PACKAGE__->meta->make_immutable;

1;
