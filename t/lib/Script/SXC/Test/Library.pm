package Script::SXC::Test::Library;
use 5.010;
use strict;
use parent 'Script::SXC::Test';
#use self;
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
    my ($self) = @_;
    $self->reader(ReaderClass->new);
    $self->compiler(CompilerClass->new(
        optimize_tailcalls           => $ENV{TEST_TAILCALLOPT},
        force_firstclass_procedures  => $ENV{TEST_FIRSTCLASS},
        inline_firstclass_procedures => $ENV{TEST_FIRSTCLASS_INLINE} // 1,
    ));
}

sub tidy {
    my ($self, $content) = @_;
    return $content if $ENV{NO_TIDY};
    my $result;

    perltidy(
        source      => \$content,
        destination => \$result,
    );

    return $result;
}

sub sx_compile_tree {
    my ($self, $content) = @_;

    my $tree = $self->sx_build_stream($content);
    my $compiled = $self->compiler->compile_tree($tree);
    isa_ok $compiled, CompiledClass;
    explain 'compiled result: ', $compiled;

    return $compiled;
}

sub sx_build_stream {
    my ($self, $content) = @_;

    my $tree = $self->reader->build_stream(\$content)->transform;
    isa_ok $tree, TreeClass;
    explain 'built tree: ', $tree;

    return $tree;
}

sub run {
    my ($self, $content) = @_;

    my $tree = $self->reader->build_stream(\$content)->transform;
    isa_ok $tree, TreeClass;
    explain 'built tree: ', $tree;

    my $compiled = $self->compiler->compile_tree($tree);
    isa_ok $compiled, CompiledClass;
    explain 'compiled result: ', $compiled;

    explain 'original: ', $content;
    explain 'compiled body: ', $self->tidy($compiled->get_body);
    my $value = $compiled->evaluate;
    explain 'returned value: ', $value;

    return $value;
}

sub run_customized {
    my $runs = 1;

    my @tailcall_options   = ($ENV{TEST_TAILCALLOPT}       // (0, 1));
    my @firstclass_options = ($ENV{TEST_FIRSTCLASS}        // (0, 1));
    my @inline_options     = ($ENV{TEST_FIRSTCLASS_INLINE} // (0, 1));
    my $total_runs         = @tailcall_options * @firstclass_options * @inline_options;

    for my $tailcall (@tailcall_options) {
        local $ENV{TEST_TAILCALLOPT} = $tailcall;

        for my $firstclass (@firstclass_options) {
            local $ENV{TEST_FIRSTCLASS} = $firstclass;

            for my $inline (@inline_options) {
                local $ENV{TEST_FIRSTCLASS_INLINE} = $inline;

                note(sprintf 'Test Run %d of %d', $runs++, $total_runs);
                note('Tailcall Optimization: ' . ($tailcall   ? 'on' : 'off'));
                note('Firstclass Procedures: ' . ($firstclass ? 'on' : 'off'));
                note('Inline Procedures:     ' . ($inline ? 'on' : 'off'));

                Test::Class->runtests;
            }
        }
    }
}

1;
