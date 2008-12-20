package Script::SXC::Test::Library::Core::Gotos;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub callstack_count {
    my $i = 0;
    $i++ until caller($i) eq 'main';
    return $i;
}

sub T700_gotos: Tests {
    my $self = self;

    # simple goto
    is self->run('(let [(p (λ (n) n)) (m 42)] (goto p 23) m)'), 23, 'goto correctly jumps to target object with correct arguments';

    # callstack
    {   is ref(my $lambda = self->run('(lambda (t p) (and (t) (goto p t p)))')), 'CODE', 'goto parses';
        my ($old, $x);
        $x = 0;
        $lambda->(sub { 
            my $new = callstack_count; 
            is $new, $old, "iteration $x still has callstack count of $old" 
                if defined $old;
            $old = $new;
            not $x++ == 5;
        }, $lambda);
    }

    # tail-call-opts
    {   is ref(my $lambda = self->run('(define foo (lambda (t) (if (t) (foo t) ()))) foo')), 'CODE', 'tailcall optimization test compiles';
        my $old;
        my $x = 0;
        is_deeply $lambda->(sub {
            my $new = callstack_count;
            if (defined($old) and $ENV{TEST_TAILCALLOPT}) {
                is $new, $old, "tailcall optimized iteration $x still has callstack count of $old";
            }
            elsif (defined $old) {
                ok $new > $old, "not tailcall optimized iteration $x increased callstack count ($old -> $new)";
            }
            $old = $new;
            return not $x++ == 5;
        }), [], 'tailcall optimization tester returned correct result';
    }

    # exceptions
    throws_ok { $self->run('(goto)') } 'Script::SXC::Exception::ParseError',
        'trying to use goto without arguments throws parse error';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/goto/, 'error message contains "goto"';
}

1;
