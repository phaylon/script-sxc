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

    my $attrs = get_all_attribute_values $self->meta, $self;
    $attrs->{value} = sprintf '#gensym~%s~%d#', $self->value, $GenSymId++;
#    say $attrs->{value};
    return SymbolClass->new(%$attrs);
}

method new_from_symbol (Str $class: Object $symbol) {

    return $class->new(get_all_attribute_values $symbol->meta, $symbol);
}

method transform_to_tree (Object $transformer, Object $compiler, Object $env, Object $context) {

    return $self->generated_symbol_item;
}

with 'Script::SXC::Compiled::SyntaxRules::Transformer::Transformation';

1;
