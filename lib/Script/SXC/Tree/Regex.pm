package Script::SXC::Tree::Regex;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use Data::Dump qw( pp );

use CLASS;
use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

method compile (Object $compiler, Object $env, Bool :$to_string?) {
    return CompiledValue->new(typehint => 'string', content => pp(join '', $self->value))
        if $to_string;
    return CompiledValue->new(typehint => 'regex', content => pp($self->value));
}

method quoted (Object $compiler!, Object $env!) {
    return $self->compile($compiler, $env);
};

with 'Script::SXC::Tree::Quotability';

CLASS->meta->make_immutable;

1;
