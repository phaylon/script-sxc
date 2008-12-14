package Script::SXC::Test::Library::Core;
use strict;
use parent 'Script::SXC::Test::Library';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub callstack_count {
    my $i = 0;
    $i++ until caller($i) eq 'main';
    return $i;
}

sub T010_operators: Tests {

    # or
    is self->run('(or 1 2)'), 1, 'or with two true values returns first true value';
    is self->run('(or #f 17)'), 17, 'or with a false and a true value returns first true value';
    is self->run('(or #f 0)'), 0, 'or with no true value is false';
    is self->run('(or 23)'), 23, 'or with one true value returns value';
    is self->run('(or 0)'), 0, 'or with one false value returns value';
    is self->run('(or)'), undef, 'or without value returns undef';

    # and
    is self->run('(and 1 2 3)'), 3, 'and with three true values returns last true value';
    is self->run('(and 1 2 0)'), 0, 'and with true and false values returns first false value';
    is self->run('(and 0 #f)'), 0, 'and with no true values returns first false value';
    is self->run('(and 23)'), 23, 'and with one true value returns value';
    is self->run('(and 0)'), 0, 'and with one false value returns value';
    is self->run('(and)'), undef, 'and without value returns undef';

    # not
    ok !self->run('(not 2)'), 'not with true value is false';
    ok self->run('(not 0)'), 'not with false value is true';
    ok self->run('(not #f 0)'), 'not with only false values is true';
    ok !self->run('(not #f 2 0)'), 'not with true value in between is false';
    ok !self->run('(not 1 2 3)'), 'not with only true values is false';
    is self->run('(not)'), undef, 'not without values is undef';

    # err
    is self->run('(err 2 3)'), 2, 'err with two defined values returns first value';
    is self->run('(err #f 23)'), 23, 'err with undefined and defined value returns defined value';
    is self->run('(err #f #f)'), undef, 'err with undefined values returns undefined';
    is self->run('(err)'), undef, 'err with no arguments returns undefined';
    is self->run('(err #f 0 23)'), 0, 'err with false value returns false value';

    # def
    ok self->run('(def 23)'), 'def with defined value returns true';
    ok self->run('(def 0)'), 'def with false but defined value returns true';
    ok !self->run('(def #f)'), 'def with undefined value returns false';
    ok self->run('(def 2 3 4)'), 'def with multiple defined arguments returns true';
    ok self->run('(def 2 0 9)'), 'def with multiple defined but false arguments returns true';
    ok !self->run('(def 2 3 #f 4)'), 'def with multiple but one undefined value returns false';
    ok !self->run('(def #f #f #f)'), 'def with multiple undefined values returns false';
}

sub T050_sequences: Tests {
    my $self = self;

    # begin
    is self->run('(begin 5 4 3 2)'), 2, 'begin sequence returns last value';
    {   is ref(my $lambda = self->run('(define foo (lambda (t) (begin (define r (t)) (if r (foo t) ()))))')), 
            'CODE', 
            'begin sequence with tailcall compiles';
        my $old;
        my $x = 0;
        is_deeply $lambda->(sub {
            my $new = callstack_count;
            if (defined($old) and $ENV{TEST_TAILCALLOPT}) {
                is $new, $old, "begin sequence with tailcall on iteration $x still has callstack count of $old";
            }
            elsif (defined $old) {
                ok $new > $old, "begin sequence with tailcall on iteration $x increased callstack count ($old -> $new)";
            }
            $old = $new;
            return not $x++ == 5;
        }), [], 'begin sequence with tailcall';
    }
    throws_ok { $self->run('(begin)') } 'Script::SXC::Exception::ParseError', 'begin without body throws parse error';
}

sub T100_conditionals: Tests {
    my $self = self;

    # if
    is self->run('(if 2 3)'), 3, 'if without alternative and true condition returns consequence';
    is self->run('(if 0 3)'), undef, 'if without alternative and false condition returns undef';
    is self->run('(if 2 3 4)'), 3, 'if with alternative and true condition returns consequence';
    is self->run('(if 0 3 4)'), 4, 'if with alternative and false condition returns alternative';
    is self->run('(if (or #f 3) (and 2 3) 4)'), 3, 'if with true condition returns consequence result';
    throws_ok { $self->run('(if)') } 'Script::SXC::Exception::ParseError', 'if without elements throws parse error';
    throws_ok { $self->run('(if 23)') } 'Script::SXC::Exception::ParseError', 'if with only single element throws parse error';
    throws_ok { $self->run('(if 1 2 3 4)') } 'Script::SXC::Exception::ParseError', 'if with more than three elements throws parse error';
}

sub T200_lambdas: Tests {
    my $self = self;

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
    throws_ok { $self->run('(lambda (x . y z) x)') } 'Script::SXC::Exception::ParseError', 
        'too many rest parameters for lambda throws parse error';
    like $@, qr/too many/i, 'error message contains "too many" part';
    like $@, qr/rest/i, 'error message contains "rest"';
    throws_ok { $self->run('(lambda (x .) x)') } 'Script::SXC::Exception::ParseError', 'missing rest parameter throws parse error';
    like $@, qr/rest/i, 'error message contains "rest"';

    # lambda λ alias
    is self->run('((λ (n) n) 23)'), 23, 'lambda shortcut λ works';

    # general exceptions
    throws_ok { $self->run('(lambda)') } 'Script::SXC::Exception::ParseError', 'lambda without arguments throws parse error';
    throws_ok { $self->run('(lambda n)') } 'Script::SXC::Exception::ParseError', 'lambda with only one argument throws parse error';
    throws_ok { $self->run('(lambda 23 42)') } 'Script::SXC::Exception::ParseError', 'lambda with invalid signature throws parse error';

    # extended parameter specifications
    is_deeply self->run('((lambda ((foo) (bar)) (list foo bar)) 2 3)'), [2, 3], 'lambda with extended signature but only names compiles';
    throws_ok { $self->run('(lambda ((:foo)) 23)') } 'Script::SXC::Exception::ParseError', 
        'invalid parameter name throws parse error';
    like $@, qr/parameter name/i, 'error message contains "parameter name"';
    throws_ok { $self->run('(lambda ((foo :fnord)) foo)') } 'Script::SXC::Exception::ParseError', 
        'invalid parameter option throws parse error';
    like $@, qr/parameter option/i, 'error message contains "parameter option"';
    throws_ok { $self->run('(lambda ((foo :where)) foo)') } 'Script::SXC::Exception::ParseError', 
        'missing expression to where clause throws parse error';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/where clause/i, 'error message contains "where clause"';
    like $@, qr/foo/, 'error message contains parameter name';
    throws_ok { $self->run('(lambda ((foo :where 2 3)) foo)') } 'Script::SXC::Exception::ParseError',
        'too many arguments for where clause throw parse error';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/where clause/i, 'error message contains "where clause"';
    like $@, qr/foo/, 'error message contains parameter name';

    # where
    {   my $lambda = self->run('(lambda ((foo :where (size foo)) . (rest :where (size rest))) (list foo rest))');
        is ref($lambda), 'CODE', 'lambda with where clauses on parameters compiles';
        is_deeply $lambda->([1, 2, 3], 4, 5, 6), [[1, 2, 3], [4, 5, 6]], 'lambda with where clause on params returns correct value';
        throws_ok { $lambda->([]) } 'Script::SXC::Exception::ArgumentError', 'unmet where clauses throw argument error';
        like $@, qr/foo/i, 'error message contains parameter name';
        throws_ok { $lambda->([1, 2]) } 'Script::SXC::Exception::ArgumentError', 'unmet where clause on rest parameter throws argument error';
        like $@, qr/rest/i, 'error message contains rest parameter name';
        throws_ok { $lambda->([], 2, 3) } 'Script::SXC::Exception::ArgumentError', 
            'unmet where clause with other met where clauses throws argument error';
        like $@, qr/foo/i, 'error message contains correct parameter name';
    }

    # argument count
    {   my $with_rest = self->run('(lambda (a b . c) (list a b c))');
        is ref($with_rest), 'CODE', 'test function for argument count check with rest compiles';
        is_deeply $with_rest->(1, 2, 3, 4), [1, 2, [3, 4]], 'valid call with optional rest receives correct arguments';
        is_deeply $with_rest->(1, 2), [1, 2, []], 'valid call without optional rest receives correct arguments';
        throws_ok { $with_rest->(1) } 'Script::SXC::Exception::ArgumentError', 'missing argument throws argument error';
        like $@, qr/missing/i, 'error message contains "missing"';
        throws_ok { $with_rest->() } 'Script::SXC::Exception::ArgumentError', 'missing arguments throw argument error';
        like $@, qr/missing/i, 'error message contains "missing"';
    }
    {   my $without_rest = self->run('(lambda (a b) (list a b))');
        is ref($without_rest), 'CODE', 'test function for argument count check without rest compiles';
        is_deeply $without_rest->(1, 2), [1, 2], 'valid call to function without rest receives correct arguments';
        throws_ok { $without_rest->(1) } 'Script::SXC::Exception::ArgumentError', 'missing argument throws argument error';
        like $@, qr/missing/i, 'error message contains "missing"';
        throws_ok { $without_rest->(1, 2, 3) } 'Script::SXC::Exception::ArgumentError', 'too many arguments throw exception';
        like $@, qr/too many/i, 'error message contains "too many"';
    }
}

sub T500_lexicals: Tests {
    my $self = shift;

    # simple let
    is self->run('(let [(n 23)] n)'), 23, 'simple let with one constant definition returns value';
    
    # common for all standard let types
    for my $let ('let', 'let*', 'let-rec') {

        # no arguments
        throws_ok { $self->run("($let)") } 'Script::SXC::Exception::ParseError',
            "$let without arguments throws parse error";
        like $@, qr/argument count/i, 'error message contains "argument count"';

        # no arguments
        throws_ok { $self->run("($let ((foo 23)))") } 'Script::SXC::Exception::ParseError',
            "$let without body throws parse error";
        like $@, qr/argument count/i, 'error message contains "argument count"';

        # invalid var spec
        throws_ok { $self->run("($let foo foo)") } 'Script::SXC::Exception::ParseError',
            "non list variable specificiation on $let throws parse error";
        like $@, qr/invalid variable specification/i, 'error message contains "invalid variable specification"';
        like $@, qr/\Q$let\E/i, 'error message contains "'.$let.'"';
        like $@, qr/list/i, 'error message contains "list"';

        # invalid pairs
        throws_ok { $self->run("($let ((x 23) foo) x)") } 'Script::SXC::Exception::ParseError',
            "non pair in variable specification on $let throws parse error";
        like $@, qr/invalid variable specification/i, 'error message contains "invalid variable specification"';
        like $@, qr/\Q$let\E/i, 'error message contains "'.$let.'"';
        like $@, qr/pair/i, 'error message contains "pair"';

        # invalid variable name
        throws_ok { $self->run("($let ((:foo 23)) 23)") } 'Script::SXC::Exception::ParseError',
            "invalid variable name in $let variable specification throws parse error";
        like $@, qr/invalid variable specification/i, 'error message contains "invalid variable specification"';
        like $@, qr/\Q$let\E/i, 'error message contains "'.$let.'"';
        like $@, qr/symbol/i, 'error message contains "symbol"';
        like $@, qr/variable name/i, 'error message contains "variable name"';

        # no pairs
        throws_ok { $self->run("($let () 23)") } 'Script::SXC::Exception::ParseError',
            "$let without anything in variable specification throws parse error";
        like $@, qr/invalid variable specification/i, 'error message contains "invalid variable specification"';
        like $@, qr/\Q$let\E/i, 'error message contains "'.$let.'"';
        like $@, qr/pairs/i, 'error message contains "pairs"';
    }

    # let with two vars and complex expressions
    {   my $lambda = self->run('(λ (p1 p2 p3) (let [(n (p1)) (m (p2))] (p3 n m)))');
        is ref($lambda), 'CODE', 'complex let with two variables and complex expressions compiles';
        is $lambda->(sub { 23 }, sub { 42 }, sub { $_[0] + $_[1] }), 65, 'complex let compiled correctly';
    }

    # normal let can't bind earlier variable
    throws_ok { $self->run('(let ((n 23) (m n)) m)') } 'Script::SXC::Exception::UnboundVar',
        'accessing variable previously declared in same let specification throws unbound variable error';
    is $@->name, 'n', 'correct unbound variable referenced in error message';
    like $@, qr/let\*.+instead/i, 'error message recommends let* instead';

    # let and let* can't bind to variable specified in same pair
    for my $let ('let', 'let*') {
        throws_ok { $self->run("($let ((n (λ (f) (f n)))) n)") } 'Script::SXC::Exception::UnboundVar',
            "accessing variable declared in same pair of $let variable specification throws unbound variable error";
        is $@->name, 'n', 'correct unbound variable referenced in error message';
        like $@, qr/let-rec.+instead/i, 'error message recommends let-rec instead';
    }

    # let*
    is self->run('(let* [(n 23) (m (λ () n))] (m))'), 23, 'let* gives variables sequential access';

    # let-rec
    {   is ref(my $letrec = self->run('(lambda (t) (let-rec ((f (λ () (if (t) (f) ())))) (f)))')), 'CODE',
            'let-rec with recursive definition compiles';
        my ($left, $num) = (5, 1);
        is_deeply $letrec->(sub {
            BAIL_OUT("too many calls in let-rec recursion test") if $num == 10;
            ok 1, sprintf 'recursive call in let-rec number %d successful', $num++;
            return --$left;
        }), [], 'let-rec with recursive definition returns correct value';
    }

    # modifications
    is self->run('(let [(n 23)] (set! n 42) n)'), 42, 'lexical value can be modified';

    # set! exceptions
    throws_ok { $self->run('(set! foo 23)') } 'Script::SXC::Exception::UnboundVar',
        'trying to set an undeclared variable throws an unbound variable error';
    is $@->name, 'foo', 'error message references correct variable';
    throws_ok { $self->run('(let ((foo 23)) (set! foo))') } 'Script::SXC::Exception::ParseError',
        'missing value to set! throws parse error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(let ((foo 23)) (set! foo 777 3))') } 'Script::SXC::Exception::ParseError',
        'too many arguments to set! throws parse error';
    like $@, qr/too many/i, 'error message contains "missing"';
    throws_ok { $self->run('(set! :foo 23)') } 'Script::SXC::Exception::ParseError',
        'trying to set a non symbol throws parse error';
    like $@, qr/symbol/i, 'error message contains "symbol"';
}

sub T510_environments: Tests {
    my $self = self;

    # direct builtin access
    {   my $list = self->run('(let ((list "new-list-symbol")) ((builtin list) list))');
        is_deeply $list, ["new-list-symbol"], 'builtin was accessed and applied successfully';
        throws_ok { $self->run('(builtin)') } 'Script::SXC::Exception::ParseError', 
            'builtin access without arguments throws parse error';
        like $@, qr/missing/i, 'error message contains "missing"';
        throws_ok { $self->run('(builtin list 23)') } 'Script::SXC::Exception::ParseError', 
            'builtin access throws parse error with too many arguments';
        like $@, qr/too many/i, 'error message contains "missing"';
        throws_ok { $self->run('(builtin shouldntexist)') } 'Script::SXC::Exception::UnboundVar', 
            'trying to access an unknown builtin throws an unbound variable error';
        is $@->name, 'shouldntexist', 'error message is about correct symbol';
        throws_ok { $self->run('(builtin :foo)') } 'Script::SXC::Exception::ParseError',
            'builtin access with non symbol argument throws parse error';
        like $@, qr/symbol/i, 'error message contains "symbol"';
    }
}

sub T525_recursions: Tests {
    my $self = self;

    my $build_counter = sub {
        my $name = shift;
        my $left  = my $start = shift(@_) || 5;
        my $count = 1;
        return sub {
            BAIL_OUT("$name: too many calls ($count)")
                if $count >= ($start + 10);
            ok 1, "$name: call number " . ( $count++ );
            return --$left;
        };
    };

    # simple recursion
    {   is ref(my $rec = self->run('(λ (t) (recurse foo ((ls (list 777))) (let ((r (t))) (if r (foo (list r ls)) ls))))')), 'CODE',
            'recurse with simple call compiles';
        is_deeply $rec->($build_counter->('simple recurse')), [1, [2, [3, [4, [777]]]]], 'simple recurse has correct values';
    }
}

sub T530_definitions: Tests {
    my $self = self;

    # simple definition on toplevel
    is self->run('(define foo 23) foo'), 23, 'top-level definition and access return correct value';
    
    # simple lambda level definition
    is self->run('((λ (n) (define m (λ () n)) (m)) 23)'), 23, 'lambda-level definition and access return correct result';

    # lots of places where we can't define
    throws_ok { $self->run('(define foo (define bar 23))') } 'Script::SXC::Exception::ParseError', 'recursive define throws parse error';
    like $@, qr/illegal definition/i, 'error message is about the illegal definition';
    throws_ok { $self->run('(let ((x 23)) (define y 23) y)') } 'Script::SXC::Exception::ParseError', 'define below let throws parse error';
    like $@, qr/illegal definition/i, 'error message is about the illegal definition';

    # argument checks
    throws_ok { $self->run('(define)') } 'Script::SXC::Exception::ParseError',
        'define with no arguments throws parse error';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/define/, 'error message contains "define"';
    throws_ok { $self->run('(define foo 23 17)') } 'Script::SXC::Exception::ParseError',
        'define with three arguments throws parse error';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/define/, 'error message contains "define"';

    # lambda definitions
    {   is ref(my $lambda = self->run('(define (foo x y . z) (list x y z)) foo')), 'CODE', 'define with lambda shortcut compiles';
        is_deeply $lambda->(1 .. 5), [1, 2, [3, 4, 5]], 'signature was parsed correctly and parameter are set as they should';
    }
    # lambda generator definitions
    {   is ref(my $genA = self->run('(define ((foo y) x) (list x y)) foo')), 'CODE', 'define with lambda generator shortcut compiles';
        is ref(my $genB = $genA->(23)), 'CODE', 'generator returned code reference';
        is_deeply $genB->(42), [23, 42], 'generator worked properly and returned correct data';
    }
    # very deep generation
    {   is ref(my $genA = self->run('(define ((((foo d) c) b) a) (list a b c d)) foo')), 'CODE', 'very deep generator compiles';
        is ref(my $genB = $genA->(1)), 'CODE', 'first generator returned code reference';
        is ref(my $genC = $genB->(2)), 'CODE', 'second generator returned code reference';
        is ref(my $genD = $genC->(3)), 'CODE', 'third generator returned code reference';
        is_deeply $genD->(4), [1 .. 4], 'fourth generator returned correct final data';
    }

    # error in shortcut definition
    throws_ok { $self->run('(define (foo x y))') } 'Script::SXC::Exception::ParseError', 
        'shortcut definition without body throws parse error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(define (() x y) (list x y))') } 'Script::SXC::Exception::ParseError', 
        'shorcut definition with empty signature list throws parse error';
    like $@, qr/empty/i, 'error message contains "empty"';
    like $@, qr/signature/i, 'error message contains "signature"';
    throws_ok { $self->run('(define (23 x y) (list x y))') } 'Script::SXC::Exception::ParseError',
        'shortcut definition with non symbol as name throws parse error';
    like $@, qr/name/i, 'error message contains "name"';
    like $@, qr/symbol/i, 'error message contains "symbol"';

    # shortcut definition with rest
    {   is ref(my $lambda = self->run('(define (foo . ls) ls)')), 'CODE', 'define shortcut with rest compiles';
        is_deeply $lambda->(2, 3, 4), [2, 3, 4], 'rest parameter in shortcut definition contains correct values';
    }

    # test definition scope
    throws_ok { $self->run('(begin (define foo 23) foo) foo') } 'Script::SXC::Exception::UnboundVar',
        'cannot access variable defined in begin from outer scope';
    is $@->name, 'foo', 'error is about correct variable name';
    throws_ok { $self->run('(define (foo n) (define bar n)) (foo 23) bar') } 'Script::SXC::Exception::UnboundVar',
        'cannot access variable defined in lambda from outer scope';
    is $@->name, 'bar', 'error is about correct variable name';
}

sub T590_reserved_symbols: Tests {
    my $self = self;

    # dot
    throws_ok { $self->run('(let ((x 23) (y 12)) (list x .))') } 'Script::SXC::Exception::ParseError',
        'dot symbol in variable definition throws parse error';
    like $@, qr/dot/i, 'error message contains "dot"';
    like $@, qr/reserved/i, 'error message contains "reserved"';
    throws_ok { $self->run('(let ((x 23) (. 12)) (list x))') } 'Script::SXC::Exception::ParseError',
        'dot symbol in variable access throws parse error';
    like $@, qr/dot/i, 'error message contains "dot"';
    like $@, qr/reserved/i, 'error message contains "reserved"';
}

sub T600_quoting: Tests {
    my $self = self;

    # constant quoting
    is_deeply self->run(q('23)), 23, 'quoting of constant number returns correct value';
    is_deeply self->run(q('"foo")), 'foo', 'quoting of constant string returns correct value';
    isa_ok self->run(q(':foo)), 'Script::SXC::Runtime::Keyword';
    isa_ok self->run(q('foo)), 'Script::SXC::Runtime::Symbol';

    # list quoting
    is_deeply self->run(q('(1 "foo" 2))), [1, 'foo', 2], 'quoting of list with constants returns correct array reference';
    is_deeply self->run(q{'(1 (2 3 (4 ())))}), [1, [2, 3, [4, []]]], 'quoting of nested lists with constants returns correct array reference';

    # simple unquote
    is_deeply self->run(q{(let [(n 23)] `(42 ,n 777))}), [42, 23, 777], 'quasiquoting with symbolic unquote returns correct structure';

    # splicing unquote
    is_deeply self->run(q{(let [(n '(1 2 3))] `(5 ,@n 6))}), [5, 1, 2, 3, 6], 'symbolic unquote-splicing integrates into structure correctly';
    is_deeply self->run(q{`(1 ,@(let [(n '(2 3))] n) 4)}), [1, 2, 3, 4], 'applicative unquote-splicing integrates into structure correctly';

    # unquote errors
    for my $unquote ('unquote', 'unquote-splicing') {

        throws_ok { $self->run("($unquote (list 2 3))") } 'Script::SXC::Exception::ParseError',
            "use of $unquote outside of quasiquote environment throws parse error";
        like $@, qr/\Q$unquote\E/, q{error message contains "$unquote"};
        like $@, qr/outside/i, 'error message contains "outside"';
    }

    # quote errors
    for my $quote ('quote', 'quasiquote') {

        throws_ok { $self->run("($quote)") } 'Script::SXC::Exception::ParseError',
            "trying to $quote without an argument throws parse error";
        like $@, qr/missing/i, 'error message contains "missing"';
        like $@, qr/\Q$quote\E/, q{error message contains "$quote"};

        throws_ok { $self->run("($quote 2 3)") } 'Script::SXC::Exception::ParseError',
            "trying to $quote with two arguments throws parse error";
        like $@, qr/too many/i, 'error message contains "too many"';
        like $@, qr/\Q$quote\E/, q{error message contains "$quote"};
    }
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

sub T800_contexts: Tests {
    my $self = self;

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

    # exceptions
    for my $context ('values->list', 'values->hash') {

        throws_ok { $self->run("($context 23)") } 'Script::SXC::Exception::ParseError',
            q{trying to use $context on non application throws parse error};
        like $@, qr/invalid/i, 'error message contains "invalid"';
        like $@, qr/\Q$context\E/, q{error message contains "$context"};
        like $@, qr/application/i, 'error message contains "application"';
    }
}

sub T850_applications: Tests {
    my $self = self;

    # simple application
    is_deeply self->run('(apply list (list 1 2 3))'), [1, 2, 3], 'apply with single list argument returns proper result';
    is_deeply self->run('(apply list 1 2 3 (list 4 5))'), [1 .. 5], 'apply with items and list as arguments returns proper result';

    # errors
    throws_ok { $self->run('(apply)') } 'Script::SXC::Exception',
        'apply without any arguments throws argument error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(apply (λ (n) n))') } 'Script::SXC::Exception',
        'apply with only one argument throws argument error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(apply list 2 3)') } 'Script::SXC::Exception',
        'apply with non list as last argument throws argument error';
    like $@, qr/last/i, 'error message contains "last"';
    like $@, qr/list/i, 'error message contains "list"';

    # list application
    is self->run('(apply (list 2 3 4) (list 1))'), 3, 'list target application returns correct value';
    throws_ok { $self->run('(apply (list 2 3 4) (list 1 2))') } 'Script::SXC::Exception::ArgumentError',
        'list target application with too many arguments throws argument error';

    # hash application
    is self->run('(apply (hash x: 2 y: 3) (list :x))'), 2, 'hash target application returns correct value';
    throws_ok { $self->run('(apply (hash x: 2 y: 3) (list :x :y))') } 'Script::SXC::Exception::ArgumentError',
        'hash target application with too many arguments throws argument error';

    # keyword invocant swap
    {   my $return = self->run('(define (r o) o) (foo: r)');
        isa_ok $return, 'Script::SXC::Runtime::Keyword';
        is "$return", 'foo', 'swapped invocant keyword has correct value';
    }
}

sub T900_edge_cases: Tests {
    my $self = self;

    # typehinting does not break execution after set
    # FIXME needs different implemented applications to be tested
    {   my $code = q{
            (define (foo x) x)
            (define (bar y) (foo y))    ; this should not be hardhinted
            (set! foo 17)
            (bar 23)
        };
        throws_ok { $self->run($code) } 'Script::SXC::Exception::TypeError',
            'change of invocant var after lambda definition throws correct type error';
        like $@, qr/invocant/i, 'error message contains "invocant"';
    }

    # shadowing builtin
    is self->run('(let ((list 23)) list)'), 23, 'builtin variables can be shadowed';
}

sub T950_errors: Tests {
    my $self  = self;
    my $class = ref $self;

    # from here
    throws_ok { $self->run('apply')->(2, 3) } 'Script::SXC::Exception::ArgumentError', 
        'first class apply with wrong arguments throws argument error';
    like $@->source_description, qr/$class/, 'source description contains caller package when called from perlspace';

    # from inside
    unless ($ENV{TEST_TAILCALLOPT}) {
        my $caller = self->run("(lambda (f)\n(let [(x 23)\n(y 42)]\n(f list x y)))");
        my $apply  = self->run('apply');
        throws_ok { $caller->($apply) } 'Script::SXC::Exception::ArgumentError',
            'first class apply with wrong arguments throws argument error';
        is $@->source_description, '(scalar)', 'source description indicates scalar evaluation';
        is $@->line_number, 4, 'source line number is correct';
    }
}

1;
