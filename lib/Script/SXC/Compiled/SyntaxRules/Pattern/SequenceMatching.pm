package Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching;
use 5.010;
use Moose::Role;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( ArrayRef Object Str );

use Scalar::Util qw( blessed );

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

has container_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has alternate_reftype => (
    is          => 'rw',
    isa         => Str,
);

method match ($item, HashRef $captures) {
#    say "item $item";

    my @checks = @{ $self->items };
    my @exprs;
    
#    say 'container class ', $self->container_class;
    if (blessed($item) and $item->isa($self->container_class)) {
#        say 'blessed';
        @exprs = @{ $item->contents };
    }
    elsif ($self->alternate_reftype and ref $item and ref $item eq $self->alternate_reftype) {
        @exprs = @$item;
    }
    else {
        return undef;
    }

    while (my $subpattern = shift @checks) {
#        say "subpattern $subpattern";

        return undef
            unless @exprs;

        my $expr = shift @exprs;

        return undef
            unless $subpattern->match($expr, $captures);
    }

    return undef
        if @exprs;

    return 1;
}

1;
