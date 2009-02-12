package Script::SXC::Compiled::SyntaxRules::Placeholder;
use 5.010;
use Moose;
use Moose::Util             qw( get_all_attribute_values );
use MooseX::Types::Moose    qw( Object );
use MooseX::Method::Signatures;

use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Tree::Symbol';

has environment => (
    is          => 'ro',
    isa         => Object,
    required    => 1,
);

around compile => sub ($next, $self, $compiler, $local_env, @rest) {

    return $self->$next($compiler, $self->environment, @rest);
};

method new_from_symbol (Object $symbol, Object $env) {

    return $self->new(%$symbol, environment => $env);
};

__PACKAGE__->meta->make_immutable;

1;
