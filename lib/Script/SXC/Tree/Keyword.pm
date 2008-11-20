package Script::SXC::Tree::Keyword;
use Moose;
use MooseX::Method::Signatures;

use Data::Dump qw( pp );

use Script::SXC::Runtime;

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::SingleValue';

my $Template = 'Script::SXC::Runtime::make_keyword(%s)';

method compile (Object $compiler, Object $env, Bool :$to_string) {
    return CompiledValue->new(
        typehint    => ($to_string ? 'string' : 'keyword'),
        content     => ($to_string ? pp($self->value) : sprintf($Template, pp($self->value))),
    );
};

__PACKAGE__->meta->make_immutable;

1;
