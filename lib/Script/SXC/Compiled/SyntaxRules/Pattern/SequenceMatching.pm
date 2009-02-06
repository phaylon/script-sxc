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

method match ($item, Object $ctx, ArrayRef $coordinates = []) {

    my @checks = @{ $self->items };
    my @exprs;

    # only the same kind of container can match
    if (blessed($item) and $item->isa($self->container_class)) {
        @exprs = @{ $item->contents };
    }
    elsif ($self->alternate_reftype and ref $item and ref $item eq $self->alternate_reftype) {
        @exprs = @$item;
    }
    else {
        return undef;
    }

    # work your way through subpatterns
    while (my $subpattern = shift @checks) {

        # greedy patterns act on no or all left over expressions
        if ($subpattern->is_greedy) {

            # capture storage coordinates
            my @coordinates = (@$coordinates, 0);
            
            # match every expression
            for my $expr (@exprs) {
                return undef
                    unless $subpattern->match($expr, $ctx, \@coordinates);

                # increase latest index in coordinates to next
                $coordinates[-1]++;
            }

            return 1;
        }

        # not greedy, single pattern requires single expression
        else {

            # we ran out of expressions, no match
            return undef
                unless @exprs;

            # remove one expression
            my $expr = shift @exprs;

            # stop here if the subpattern doesn't match
            return undef
                unless $subpattern->match($expr, $ctx, $coordinates);
        }
    }

    # we ran out of subpatterns, no match
    return undef
        if @exprs;

    # everything seems accounted for
    return 1;
}

1;
