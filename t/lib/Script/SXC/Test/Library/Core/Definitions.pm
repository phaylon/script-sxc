package Script::SXC::Test::Library::Core::Definitions;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

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

1;
