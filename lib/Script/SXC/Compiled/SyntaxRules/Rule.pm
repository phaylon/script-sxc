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

    my $context = Context->new;
    return $self->match_pattern($exprs, $context) ? $context : undef;

#    my (%capture_values, @iteration_values);
#    my $is_match = $self->match_pattern($exprs, \%capture_values, \@iteration_values);
#    say 'captures ', join ', ', keys %capture_values;
#    return $is_match ? \%capture_values : undef;
}

1;
