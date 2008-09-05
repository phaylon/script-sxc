package Script::SXC::Token::DirectTransform;
use Moose::Role;

use namespace::clean -except => 'meta';
use Method::Signatures;

requires qw( tree_item_class );

method transform {
    my $item_class = $self->tree_item_class;
    Class::MOP::load_class($item_class);
    return $item_class->new_from_token(
        $self,
        value => $self->value,
    );
};

1;
