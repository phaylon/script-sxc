package Script::SXC::Compiled::SyntaxRules::Transformer::LibraryItem;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Tree::Symbol';

method BUILD {
    $self->value($self->name);
}

method transform_to_tree (Object $transformer, Object $compiler, Object $env, HashRef $captures) {

    #Class::MOP::load_class($self->library);
    #return $self->library->new->get($self->name);
    return $self;
}

method find_associated_item (Object $compiler, Object $env) {

    Class::MOP::load_class($self->library);
    return $self->library->new->get($self->name . '');
}

with 'Script::SXC::Library::Item::Location';
with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';

1;
