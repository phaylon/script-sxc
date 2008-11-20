package Script::SXC::Test::Compiler;
use strict;
use parent 'Script::SXC::Test';
use self;
use CLASS;
use Test::Most;
use aliased 'Script::SXC::Reader',      'ReaderClass';
use aliased 'Script::SXC::Tree',        'TreeClass';
use aliased 'Script::SXC::Compiler',    'CompilerClass';
use aliased 'Script::SXC::Compiled',    'CompiledClass';
use Data::Dump qw( dump );

use Script::SXC::Test::Util qw( assert_ok list_ok symbol_ok builtin_ok quote_ok );

CLASS->mk_accessors(qw( reader compiler ));

sub evaluate {
    my ($content) = args;

    my $tree = self->reader->build_stream(\$content)->transform;
    isa_ok $tree, TreeClass;
    explain 'built tree: ', $tree;

    my $compiled = self->compiler->compile_tree($tree);
    isa_ok $compiled, CompiledClass;
    explain 'compiled result: ', $compiled;

    my $value = $compiled->evaluate;
    explain 'compiled body: ', $compiled->get_body;
    explain 'returned value: ', $value;

    return $value;
}

sub setup_objects: Test(setup) {
    self->reader(ReaderClass->new);
    self->compiler(CompilerClass->new);
}

sub T00_simple_expressions: Tests {

    # numbers
    is self->evaluate('23'), 23, 'simple integer evaluation';
    is self->evaluate('23.5'), 23.5, 'simple float evaluation';

    # strings
    is self->evaluate('"foo"'), 'foo', 'simple string evaluation';
    is self->evaluate('"foo\"bar"'), 'foo"bar', 'simple string evaluation with special char';

    # booleans
    is self->evaluate('#t'), 1, 'simple true boolean';
    is self->evaluate('#f'), undef, 'simple false boolean';

    # keywords
    {   my $foo = self->evaluate(':foo');
        isa_ok $foo, 'Script::SXC::Runtime::Keyword';
        is "$foo", 'foo', 'runtime keyword is correctly built';
    }
}

sub T10_lists: Tests {

    # empty list
    is_deeply self->evaluate('()'), [], 'empty list';
}

1;
