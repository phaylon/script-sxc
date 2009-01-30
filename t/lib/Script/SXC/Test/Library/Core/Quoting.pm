package Script::SXC::Test::Library::Core::Quoting;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T600_quoting: Tests {
    my $self = shift;

    # constant quoting
    is_deeply $self->run(q('23)), 23, 'quoting of constant number returns correct value';
    is_deeply $self->run(q('"foo")), 'foo', 'quoting of constant string returns correct value';
    isa_ok $self->run(q(':foo)), 'Script::SXC::Runtime::Keyword';
    isa_ok $self->run(q('foo)), 'Script::SXC::Runtime::Symbol';

    # list quoting
    is_deeply $self->run(q('(1 "foo" 2))), [1, 'foo', 2], 'quoting of list with constants returns correct array reference';
    is_deeply $self->run(q{'(1 (2 3 (4 ())))}), [1, [2, 3, [4, []]]], 'quoting of nested lists with constants returns correct array reference';

    # simple unquote
    is_deeply $self->run(q{(let [(n 23)] `(42 ,n 777))}), [42, 23, 777], 'quasiquoting with symbolic unquote returns correct structure';

    # splicing unquote
    is_deeply $self->run(q{(let [(n '(1 2 3))] `(5 ,@n 6))}), [5, 1, 2, 3, 6], 'symbolic unquote-splicing integrates into structure correctly';
    is_deeply $self->run(q{`(1 ,@(let [(n '(2 3))] n) 4)}), [1, 2, 3, 4], 'applicative unquote-splicing integrates into structure correctly';

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

1;
