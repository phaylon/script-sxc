package Script::SXC::Tree;
use Moose;
use MooseX::AttributeHelpers;

use Script::SXC::Types qw( ArrayRef );

use namespace::clean -except => 'meta';
use Method::Signatures;

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
