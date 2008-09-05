package Script::SXC::Tree::Container;
use Moose::Role;
use MooseX::AttributeHelpers;

use Script::SXC::Types qw( ArrayRef );

use namespace::clean -except => 'meta';

has contents => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef,
    required    => 1,
    default     => sub { [] },
    provides    => {
        'count'     => 'content_count',
        'get'       => 'get_content_item',
    },
);

1;
