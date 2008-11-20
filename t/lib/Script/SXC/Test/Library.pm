package Script::SXC::Test::Library;
use strict;
use parent 'Script::SXC::Test';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );
use Perl::Tidy qw( perltidy );
use Class::C3;
use aliased 'Script::SXC::Reader',      'ReaderClass';
use aliased 'Script::SXC::Tree',        'TreeClass';
use aliased 'Script::SXC::Compiler',    'CompilerClass';
use aliased 'Script::SXC::Compiled',    'CompiledClass';

CLASS->mk_accessors(qw( reader compiler ));

sub setup_objects: Test(setup) {
    self->reader(ReaderClass->new);
    self->compiler(CompilerClass->new(
        optimize_tailcalls          => $ENV{TEST_TAILCALLOPT},
        force_firstclass_procedures => $ENV{TEST_FIRSTCLASS},
    ));
}

sub tidy {
    my ($content) = args;
    return $content if $ENV{NO_TIDY};
    my $result;

    perltidy(
        source      => \$content,
        destination => \$result,
    );

    return $result;
}

sub run {
    my ($content) = args;

    my $tree = self->reader->build_stream(\$content)->transform;
    isa_ok $tree, TreeClass;
    explain 'built tree: ', $tree;

    my $compiled = self->compiler->compile_tree($tree);
    isa_ok $compiled, CompiledClass;
    explain 'compiled result: ', $compiled;

    explain 'original: ', $content;
    explain 'compiled body: ', self->tidy($compiled->get_body);
    my $value = $compiled->evaluate;
    explain 'returned value: ', $value;

    return $value;
}

1;
