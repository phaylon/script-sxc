package Script::SXC::Test::Library::Data::Code;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );

sub T500_code: Tests {
    my $self = shift;

    # predicate
    is $self->run('(code? +)'), 1, 'code predicate works on builtin';
    is $self->run('(code? (λ () 5))'), 1, 'code predicate works on lambda';
    is $self->run('(code? 23)'), undef, 'code predicate returns undefined value on integer';
    is $self->run('(code? + (λ (n) n) -)'), 1, 'code predicate is true on multiple code references';
    is $self->run('(code? + 4 (λ () 3))'), undef, 'code predicate returns undefined value with non code reference in multiple arguments';

    throws_ok { $self->run('(code?)') } 'Script::SXC::Exception', 'code? without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/code\?/, 'error message contains "code?"';

    # curry
    {   is ref(my $plustwo = $self->run('(curry + 2)')), 'CODE', 'builtin currying compiles';
        is $plustwo->(3, 6), 11, 'curried builtin returns correct result';
        is $plustwo->(), 2, 'curried builtin returns correct result without arguments';
    }
    {   is ref(my $rec = $self->run('(define (rec foo bar) { foo: foo bar: bar }) (curry rec 23)')), 'CODE', 'lambda currying compiles';
        is_deeply $rec->(42), { foo => 23, bar => 42 }, 'curried lambda returns correct result';
    }
    is_deeply $self->run('((curry list 1 2 3) 4 5 6)'), [1 .. 6], 'multiple argument currying returns correct result';
    throws_ok { $self->run('(curry +)') } 'Script::SXC::Exception', 'curry with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/curry/, 'error message contains "curry"';

    # rcurry
    {   is ref(my $plustwo = $self->run('(rcurry + 2)')), 'CODE', 'builtin rcurrying compiles';
        is $plustwo->(3, 6), 11, 'rcurried builtin returns correct result';
        is $plustwo->(), 2, 'rcurried builtin returns correct result without arguments';
    }
    {   is ref(my $rec = $self->run('(define (rec foo bar) { foo: foo bar: bar }) (rcurry rec 23)')), 'CODE', 'lambda rcurrying compiles';
        is_deeply $rec->(42), { foo => 42, bar => 23 }, 'rcurried lambda returns correct result';
    }
    is_deeply $self->run('((rcurry list 1 2 3) 4 5 6)'), [4 .. 6, 1 .. 3], 'multiple argument rcurrying returns correct result';
    throws_ok { $self->run('(rcurry +)') } 'Script::SXC::Exception', 'rcurry with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/rcurry/, 'error message contains "rcurry"';
}

1;
