package Script::SXC::Test::Library::Core;
use strict;
use parent 'Script::SXC::Test::Library';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T010_operators: Tests {

    # or
    is self->run('(or 1 2)'), 1, 'or with two true values returns first true value';
    is self->run('(or #f 17)'), 17, 'or with a false and a true value returns first true value';
    is self->run('(or #f 0)'), 0, 'or with no true value is false';

    # and
    is self->run('(and 1 2 3)'), 3, 'and with three true values returns last true value';
    is self->run('(and 1 2 0)'), 0, 'and with true and false values returns first false value';
    is self->run('(and 0 #f)'), 0, 'and with no true values returns first false value';

    # not
    ok !self->run('(not 2)'), 'not with true value is false';
    ok self->run('(not 0)'), 'not with false value is true';
    ok self->run('(not #f 0)'), 'not with only false values is true';
    ok !self->run('(not #f 2 0)'), 'not with true value in between is false';
    ok !self->run('(not 1 2 3)'), 'not with only true values is false';
}

sub T100_conditionals: Tests {

    # if
    is self->run('(if 2 3)'), 3, 'if without alternative and true condition returns consequence';
    is self->run('(if 0 3)'), undef, 'if without alternative and false condition returns undef';
    is self->run('(if 2 3 4)'), 3, 'if with alternative and true condition returns consequence';
    is self->run('(if 0 3 4)'), 4, 'if with alternative and false condition returns alternative';
    is self->run('(if (or #f 3) (and 2 3) 4)'), 3, 'if with true condition returns consequence result';
}

sub T200_lambdas: Tests {

    # simple without scoping tests
    {   my $lambda = self->run('(lambda () 23)');
        is ref($lambda), 'CODE', 'simple lambda returned code reference';
        is $lambda->(), 23, 'execution of lambda returned evaluated body expression';
    }

    # simple with list param
    {   my $lambda = self->run('(lambda foo 23)');
        is ref($lambda), 'CODE', 'lambda with list parameter returned code reference';
        is $lambda->(), 23, 'execution of lambda returned evaluated body expression';
    }

    # simple with one param
    {   my $lambda = self->run('(lambda (n) 23)');
        is ref($lambda), 'CODE', 'lambda with one parameter returned code reference';
        is $lambda->(42), 23, 'execution of lambda returned evaluated body expression';
    }

    # simple with one param and environment access
    {   my $lambda = self->run('(lambda (n) n)');
        is ref($lambda), 'CODE', 'lambda with one parameter returned code reference';
        is $lambda->(777), 777, 'lambda with one parameter and local environment access returns passed value';
    }

    # be one with the cons
    {   my $kons = self->run('(lambda (n m) (lambda (f) (f n m)))');
        is ref($kons), 'CODE', 'kons lambda definition returned code reference';
        my $kar = self->run('(lambda (p) (p (lambda (n m) n)))');
        is ref($kar), 'CODE', 'kar lambda definition returned code reference';
        my $kdr = self->run('(lambda (p) (p (lambda (n m) m)))');
        is ref($kdr), 'CODE', 'kdr lambda definition returned code reference';
        my $pair = $kons->(23, 42);
        is ref($pair), 'CODE', 'kons lambda code reference returns pair as code reference';
        is $kar->($pair), 23, 'kar applied to pair returns first value';
        is $kdr->($pair), 42, 'kdr applied to pair returns second value';
    }

    # direct lambda application
    is self->run('((lambda (n) n) 23)'), 23, 'direct lambda application returned passed value';

    # two parameters and a rest
    is self->run('((lambda (x y . z) x) 1 2 3 4)'), 1, 'first parameter of semi complex signature correct';
    is self->run('((lambda (x y . z) y) 1 2 3 4)'), 2, 'second parameter of semi complex signature correct';
    is_deeply self->run('((lambda (x y . z) z) 1 2 3 4)'), [3, 4], 'rest parameter of semi complex signature correct';

    # lambda λ alias
    is self->run('((λ (n) n) 23)'), 23, 'lambda shortcut λ works';
}

sub T500_lexicals: Tests {

    # simple let
    is self->run('(let [(n 23)] n)'), 23, 'simple let with one constant definition returns value';

    # let with two vars and complex expressions
    {   my $lambda = self->run('(λ (p1 p2 p3) (let [(n (p1)) (m (p2))] (p3 n m)))');
        is ref($lambda), 'CODE', 'complex let with two variables and complex expressions compiles';
        is $lambda->(sub { 23 }, sub { 42 }, sub { $_[0] + $_[1] }), 65, 'complex let compiled correctly';
    }

    # let*
    is self->run('(let* [(n 23) (m (λ () n))] (m))'), 23, 'let* gives variables sequential access';

    # modifications
    is self->run('(let [(n 23)] (set! n 42) n)'), 42, 'lexical value can be modified';
}

sub T530_definitions: Tests {

    # simple definition on toplevel
    is self->run('(define foo 23) foo'), 23, 'top-level definition and access return correct value';
    
    # simple lambda level definition
    is self->run('((λ (n) (define m (λ () n)) (m)) 23)'), 23, 'lambda-level definition and access return correct result';
}

sub T600_quoting: Tests {

    # constant quoting
    is_deeply self->run(q('23)), 23, 'quoting of constant number returns correct value';
    is_deeply self->run(q('"foo")), 'foo', 'quoting of constant string returns correct value';

    # list quoting
    is_deeply self->run(q('(1 "foo" 2))), [1, 'foo', 2], 'quoting of list with constants returns correct array reference';
    is_deeply self->run(q{'(1 (2 3 (4 ())))}), [1, [2, 3, [4, []]]], 'quoting of nested lists with constants returns correct array reference';

    # simple unquote
    is_deeply self->run(q{(let [(n 23)] `(42 ,n 777))}), [42, 23, 777], 'quasiquoting with symbolic unquote returns correct structure';

    # splicing unquote
    is_deeply self->run(q{(let [(n '(1 2 3))] `(5 ,@n 6))}), [5, 1, 2, 3, 6], 'symbolic unquote-splicing integrates into structure correctly';
    is_deeply self->run(q{`(1 ,@(let [(n '(2 3))] n) 4)}), [1, 2, 3, 4], 'applicative unquote-splicing integrates into structure correctly';
}

sub callstack_count {
    my $i = 0;
    $i++ until caller($i) eq 'main';
    return $i;
}

sub T700_gotos: Tests {

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
    {   is ref(my $lambda = self->run('(define foo (lambda (t) (if (t) (foo t) ())) foo)')), 'CODE', 'tailcall optimization test compiles';
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
}

sub T800_contexts: Tests {

    # list apply
    {   is ref(my $lambda = self->run('(lambda (p) (values->list (p 23)))')), 'CODE', 'values->list compiles';
        is_deeply $lambda->(sub { my $x = shift; return $x, $x * 2, $x * 3 }), [23, 46, 69], 
            'values->list returns list of correct values';
    }

    # hash apply
    {   is ref(my $lambda = self->run('(lambda (p) (values->hash (p 23)))')), 'CODE', 'values->hash parses';
        is_deeply $lambda->(sub { my $x = shift; return foo => $x, bar => $x * 2 }), { foo => 23, bar => 46 }, 
            'values->hash returns hash with correct pairs';
    }
}

1;
