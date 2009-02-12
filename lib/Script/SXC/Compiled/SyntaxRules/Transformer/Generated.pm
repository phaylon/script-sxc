package Script::SXC::Compiled::SyntaxRules::Transformer::Generated;
use 5.010;
use Moose;
use Moose::Util             qw( get_all_attribute_values );
use MooseX::Types::Moose    qw( Object );
use MooseX::Method::Signatures;

use Script::SXC::lazyload
   ['Script::SXC::Tree::Symbol', 'SymbolClass'];

use namespace::clean -except => 'meta';

extends 'Script::SXC::Tree::Symbol';

has generated_symbol_item => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    lazy        => 1,
    builder     => 'generate_symbol',
);

my $GenSymId = 0;

method generate_symbol {

    # fetch all our current attributes
    my $attrs = get_all_attribute_values $self->meta, $self;

    # generate an internal symbol
    $attrs->{value} = sprintf '#gensym~%s~%d#', $self->value, $GenSymId++;

    # return a fresh symbol class
    return SymbolClass->new(%$attrs);
}

method new_from_symbol (Str $class: Object $symbol) {

    # create a new instance with the same values as the symbol
    return $class->new(get_all_attribute_values $symbol->meta, $symbol);
}

method transform_to_tree (Object $transformer, Object $compiler, Object $env, Object $context) {

    # return our generated internal symbol
    return $self->generated_symbol_item;
}

with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';

__PACKAGE__->meta->make_immutable;

1;
