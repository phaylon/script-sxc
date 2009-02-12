package Script::SXC::Compiled::SyntaxRules::Transformer::LibraryItem;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Tree::Symbol';

method BUILD {

    # set the symbol value to the name of the library item
    $self->value($self->name);
}

method transform_to_tree (Object $transformer, Object $compiler, Object $env, Object $context) {

    # we can substitute as the target symbol, so we just return ourselves
    return $self;
}

method find_associated_item (Object $compiler, Object $env) {

    # load the library and return the item we represent
    Class::MOP::load_class($self->library);
    return $self->library->new->get($self->name . '');
}

with 'Script::SXC::Library::Item::Location';
with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';

__PACKAGE__->meta->make_immutable;

1;
