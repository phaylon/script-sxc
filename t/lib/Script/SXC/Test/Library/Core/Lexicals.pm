package Script::SXC::Test::Library::Core::Lexicals;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T100_let: Tests {

    # simple
    is self->run('(let [(n 23)] n)'), 23, 'simple let with one constant definition returns value';

    # let with two vars and complex expressions
    {   my $lambda = self->run('(λ (p1 p2 p3) (let [(n (p1)) (m (p2))] (p3 n m)))');
        is ref($lambda), 'CODE', 'complex let with two variables and complex expressions compiles';
        is $lambda->(sub { 23 }, sub { 42 }, sub { $_[0] + $_[1] }), 65, 'complex let compiled correctly';
    }
}

sub T050_let_common: Tests {
    my $self = self;

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
}

sub T200_let_binding: Tests {
    my $self = self;

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
}

sub T120_sequential_let: Tests {

    is self->run('(let* [(n 23) (m (λ () n))] (m))'), 23, 'let* gives variables sequential access';
}

sub T140_recursive_let: Tests {

    is ref(my $letrec = self->run('(lambda (t) (let-rec ((f (λ () (if (t) (f) ())))) (f)))')), 'CODE',
        'let-rec with recursive definition compiles';
    my ($left, $num) = (5, 1);
    is_deeply $letrec->(sub {
        BAIL_OUT("too many calls in let-rec recursion test") if $num == 10;
        ok 1, sprintf 'recursive call in let-rec number %d successful', $num++;
        return --$left;
    }), [], 'let-rec with recursive definition returns correct value';
}

sub T600_modifications: Tests {
    my $self = self;

    is self->run('(let [(n 23)] (set! n 42) n)'), 42, 'lexical value can be modified';

    # can't modify globals
    throws_ok { $self->run('(set! + 23)') } 'Script::SXC::Exception::ParseError',
        'trying to modify global variable throws parse error';
    like $@, qr/global/i, 'error message contains "global"';
    like $@, qr/modif(?:y|ication)/i, 'error message contains "modify" or "modification"';
    is $@->type, 'illegal_modification_of_global', 'exception has correct type';

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

sub T700_given: Tests {
    my $self = self;

    is self->run('(given 23 _)'), 23, 'simplest given returns correct result';
    is self->run('(given 7 (* _ 2))'), 14, 'given topic in application returns correct result';

    throws_ok { $self->run('(given 23)') } 'Script::SXC::Exception', 'given with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/given/, 'error message contains "given"';
}

1;
