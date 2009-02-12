package Script::SXC::Compiled::SyntaxRules::Rule;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( CodeRef Object );

use Script::SXC::lazyload
    'Script::SXC::Compiled::SyntaxRules::Context';

use namespace::clean -except => 'meta';

has pattern => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'match_pattern' => 'match',
    },
);

has transformer => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'build_tree'    => 'build_tree',
    },
);

method match (ArrayRef $exprs) {

    # create a context, but return it only if we have a match
    my $context = Context->new(rule => $self);
    return $self->match_pattern($exprs, $context) ? $context : undef;
}

__PACKAGE__->meta->make_immutable;

1;
