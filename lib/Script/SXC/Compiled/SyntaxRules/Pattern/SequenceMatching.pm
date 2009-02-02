package Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching;
use Moose::Role;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( ArrayRef Object );

use namespace::clean -except => 'meta';

has items => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[Object],
    required    => 1,
    default     => sub { [] },
    provides    => {
        'count'     => 'item_count',
        'get'       => 'get_item',
        'push'      => 'add_item',
    },
);

1;
