package Script::SXC::Test::Library::Data::General;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );
use self;

sub T000_general: Tests {
    my $self = self;

    # emptiness
    ok self->run('(empty? ())'), 'empty? returns true on empty list';
    ok self->run('(empty? "")'), 'empty? returns true on empty string';
    ok self->run('(empty? (hash))'), 'empty? returns true on empty hash';
    ok self->run('(empty? () "" (hash))'), 'empty? returns true on multiple empty arguments';
    ok !self->run('(empty? (list 23) "" (hash))'), 'empty? returns false with non empty list';
    ok !self->run('(empty? (list) "23" (hash))'), 'empty? returns false with non empty string';
    ok !self->run('(empty? (list) "" (hash x: 23))'), 'empty? returns false with non empty hash';
    ok !self->run('(empty? (list 23) (hash) "foo")'), 'empty? returns false with multiple non empty arguments';
    throws_ok { $self->run('(empty?)') } 'Script::SXC::Exception', 'empty? without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(empty? "" :x ())') } 'Script::SXC::Exception::ArgumentError', 'empty? with invalid argument throws error';
    like $@, qr/invalid/i, 'error message contains "invalid"';
    like $@, qr/hash/i, 'error message contains "hash"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/string/i, 'error message contains "string"';
    like $@, qr/argument 1/i, 'error message contains "argument 1"';

    # reverse
    is self->run('(reverse "foo")'), 'oof', 'string reverse returns reversed string';
    is_deeply self->run('(reverse (list 1 2 3))'), [3, 2, 1], 'list reverse returns reversed list';
    is_deeply self->run('(reverse (hash x: 2 y: 3))'), { 2 => 'x', 3 => 'y' }, 'hash reverse returns reversed hash';
    is_deeply self->run('(reverse ())'), [], 'reverse of empty list is empty list';
    throws_ok { $self->run('(reverse)') } 'Script::SXC::Exception', 'reverse without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(reverse (list 2 3) (hash 4 5))') } 'Script::SXC::Exception', 'reverse with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(reverse :foo)') } 'Script::SXC::Exception::ArgumentError', 'reverse throws error on invalid argument type';
    like $@, qr/invalid/i, 'error message contains "invalid"';
    like $@, qr/hash/i, 'error message contains "hash"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/string/i, 'error message contains "string"';

    # exists?
    ok self->run('(exists? (list 1 2 3) 1)'), 'exists? is true on existing list element';
    ok self->run('(exists? (hash x: 2 y: 3) :x)'), 'exists? is true on existing hash key';
    ok self->run('(exists? (list 1 2 3) 1 2)'), 'exists? is true on multiple existing list elements';
    ok self->run('(exists? (hash x: 2 y: 3) :x :y)'), 'exists? is true on multiple existing hash keys';
    ok !self->run('(exists? (list 2 3 4) 9)'), 'exists? is false on non existing list element';
    ok !self->run('(exists? (hash x: 23) :y)'), 'exists? is false on non existing hash key';
    ok !self->run('(exists? (list 1 2 3) 1 2 5)'), 'exists? is false with some existing, some non existing list elements';
    ok !self->run('(exists? (hash x: 2 y: 3) :x :y :z)'), 'exists? is false with some existing, some non existing hash keys';
    throws_ok { $self->run('(exists?)') } 'Script::SXC::Exception', 'exists? without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(exists? (list 2 3))') } 'Script::SXC::Exception', 'exists? with not enough arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(exists? :x :y)') } 'Script::SXC::Exception::ArgumentError', 'exists? throws error on invalid argument type';
    like $@, qr/invalid/i, 'error message contains "invalid"';
    like $@, qr/hash/i, 'error message contains "hash"';
    like $@, qr/list/i, 'error message contains "list"';

    # copying
    {   is ref(my $copy = self->run('(lambda (x) (copy x))')), 'CODE', 'copy procedure compiles';
        is $copy->('foo'), 'foo', 'string copying returns correct string';

        my $ls_orig = [1 .. 5];
        is_deeply( (my $ls_new = $copy->($ls_orig)), $ls_orig, 'list copying returns correct list' );
        isnt refaddr($ls_orig), refaddr($ls_new), 'lists are different references';

        my $hs_orig = {1 .. 4};
        is_deeply( (my $hs_new = $copy->($hs_orig)), $hs_orig, 'hash copying returns correct hash' );
        isnt refaddr($hs_orig), refaddr($hs_new), 'hashes are different references';

        my $kw_orig = self->run(':foo');
        is( (my $kw_new = $copy->($kw_orig))->value, $kw_orig->value, 'keyword copying returns correct keyword' );
        is refaddr($kw_orig), refaddr($kw_new), 'keywords are same references';

        my $sy_orig = self->run(q('foo));
        is( (my $sy_new = $copy->($sy_orig))->value, $sy_orig->value, 'symbol copying returns correct symbol' );
        isnt refaddr($sy_orig), refaddr($sy_new), 'symbols are different references';

        throws_ok { $self->run('(copy)') } 'Script::SXC::Exception', 'copy without arguments throws error';
        like $@, qr/missing/i, 'error message contains "missing"';
        throws_ok { $self->run('(copy 23 17)') } 'Script::SXC::Exception', 'copy with two parameters throws error';
        like $@, qr/too many/i, 'error message contains "too many"';
        throws_ok { $self->run('(copy (λ () 23))') } 'Script::SXC::Exception::ArgumentError', 'copy throws argument error on code ref';
        like $@, qr/invalid/i, 'error message contains "invalid"';
        like $@, qr/hash/i, 'error message contains "hash"';
        like $@, qr/list/i, 'error message contains "list"';
        like $@, qr/string/i, 'error message contains "string"';
        like $@, qr/keyword/i, 'error message contains "keyword"';
        like $@, qr/symbol/i, 'error message contains "symbol"';
        like $@, qr/CODE/, 'error message mentions stringified code reference';
    }

    # true?
    is self->run('(true?)'), undef, 'true? without arguments returns undefined value';
    is self->run('(true? 0)'), undef, 'true? returns undefined value with false argument';
    is self->run('(true? 1 2 23)'), 23, 'true? returns last true value if all are true';
    is self->run('(true? 1 2 0 4)'), undef, 'true? returns undefined value with all true but one';
    is_deeply self->run('(true? (list))'), [], 'true? returns empty list when argument is empty list';

    # false?
    is self->run('(false?)'), 1, 'false? returns true without arguments';
    is self->run('(false? #f)'), 1, 'false? returns true with false argument';
    is self->run('(false? "foo")'), undef, 'false? returns undefined value with true argument';
    is self->run('(false? #f "" 0)'), 1, 'false? is true with multiple false arguments';
    is self->run('(false? #f 0 (list) "")'), undef, 'false? returns undefined value with empty list argument';
}

1;
