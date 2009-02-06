package Script::SXC::Compiled::SyntaxRules::Transformer::Iteration;
use 5.010;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( Bool Int );

use Data::Dump qw( pp );

use signatures;
use namespace::clean -except => 'meta';

has is_iterative => (
    is          => 'rw',
    isa         => Bool,
    default     => 0,
);

has iteration_level => (
    is          => 'rw',
    isa         => Int,
    default     => 0,
);

around transform_to_tree => sub ($next, $self, $transformer, $compiler, $env, $context, $coordinates) {
    $coordinates //= [];

    unless ($self->is_iterative) {
        return $self->$next($transformer, $compiler, $env, $context, $coordinates);
    }

    my $level = @$coordinates + 1;
    my $count = $context->get_iteration_count_on_level($level);

    return unless $count;

    my @coordinates = (@$coordinates, 0);
    my @transformed;

    for my $index (0 .. $count - 1) {

        $coordinates[-1] = $index;
        push @transformed, $self->$next($transformer, $compiler, $env, $context, \@coordinates);
    }

    return @transformed;
};

1;
