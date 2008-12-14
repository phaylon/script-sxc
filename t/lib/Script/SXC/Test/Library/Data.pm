package Script::SXC::Test::Library::Data;
use strict;
use parent 'Script::SXC::Test::Library';
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
}

sub T050_smartmatch: Tests {
    my $self = self;


}

sub T100_lists: Tests {
    my $self = self;

    # creation
    is_deeply self->run('(list 1 (list 2 3) (list (list 4 (list 5))))'), [1, [2, 3], [[4, [5]]]], 'explicit list creation';
    is_deeply self->run('(list)'), [], 'explicit empty list creation';
    is_deeply self->run('()'), [], 'implicit empty list creation';

    # head
    is self->run('(head (list 1 2 3))'), 1, 'head without argument returns first element';
    is self->run('(head (list))'), undef, 'head without argument and with empty list returns undef';
    is_deeply self->run('(head (list 23 2 3) 1)'), [23], 'head with one as number returns list with one element';
    is_deeply self->run('(head (list 1 2 3 4) 2)'), [1, 2], 'head with number returns first number of elements';
    is_deeply self->run('(head (list 1 2 3) 5)'), [1, 2, 3], 'head with number and too small list returns complete list';
    is_deeply self->run('(head (list) 3)'), [], 'head with number but empty list returns empty list';
    throws_ok { $self->run('(head)') } 'Script::SXC::Exception', 'head without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(head 23)') } 'Script::SXC::Exception', 'head with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';
    throws_ok { $self->run('(head (list 2 3) 4 5)') } 'Script::SXC::Exception', 'head with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';

    # tail
    is_deeply self->run('(tail (list 1 2 3))'), [2, 3], 'tail without number returns all but first element';
    is_deeply self->run('(tail (list))'), [], 'tail without number and with empty list returns empty list';
    is_deeply self->run('(tail (list 1 2 3 4) 2)'), [3, 4], 'tail with number returns number of elements from the end of the list';
    is_deeply self->run('(tail (list 1 2 3) 5)'), [1, 2, 3], 'tail with number and too small list returns complete list';
    is_deeply self->run('(tail (list) 3)'), [], 'tail with number but empty list returns empty list';
    throws_ok { $self->run('(tail)') } 'Script::SXC::Exception', 'tail without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(tail 23)') } 'Script::SXC::Exception', 'tail with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';
    throws_ok { $self->run('(tail (list 2 3) 4 5)') } 'Script::SXC::Exception', 'tail with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';

    # size
    is self->run('(size (list "foo" "bar" "baz"))'), 3, 'size returns correct size of list';
    is self->run('(size (list))'), 0, 'size returns zero on empty list';
    throws_ok { $self->run('(size)') } 'Script::SXC::Exception', 'size without argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(size (list 2 3) 4)') } 'Script::SXC::Exception', 'size with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(size 23)') } 'Script::SXC::Exception', 'size with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';

    # last-index
    is self->run('(last-index (list 1 2 4 5 6 7))'), 5, 'last-index returns last index of list';
    is self->run('(last-index (list 23))'), 0, 'last-index returns zero with single item list';
    is self->run('(last-index (list))'), -1, 'last-index returns negative one when list is empty';
    throws_ok { $self->run('(last-index)') } 'Script::SXC::Exception', 'last-index without argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(last-index (list 2 3) 4)') } 'Script::SXC::Exception', 'last-index with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(last-index 23)') } 'Script::SXC::Exception', 'last-index with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';

    # list-ref
    is self->run('(list-ref (list 2 3 4) 1)'), 3, 'list-ref returns correct list element';
    is self->run('(list-ref (list) 3)'), undef, 'list-ref returns undef if element does not exist';
    throws_ok { $self->run('(list-ref)') } 'Script::SXC::Exception', 'list-ref without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(list-ref (list 2 3))') } 'Script::SXC::Exception', 'list-ref with missing argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(list-ref (list 2 3) 1 2)') } 'Script::SXC::Exception', 'list-ref with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(list-ref 23 7)') } 'Script::SXC::Exception', 'list-ref with non list as first argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';

    # appending lists
    is_deeply self->run('(append (list 2 3) (list 4 5))'), [2, 3, 4, 5], 'append returns new list with merge of two lists';
    is_deeply self->run('(append (list 2 3) (list 4 5) (list 3))'), [2, 3, 4, 5, 3], 'append returns new list with merge of three lists';
    throws_ok { $self->run('(append)') } 'Script::SXC::Exception', 'append without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(append (list 2 3))') } 'Script::SXC::Exception', 'append with only one argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(append (list 2 3) 4 (list 5 6))') } 'Script::SXC::Exception', 'append with non list argument throws error';
    like $@, qr/invalid\s+argument\s+1/i, 'error message contains "invalid argument 1"';
    like $@, qr/list/i, 'error message contains "list"';

    # predicate
    ok self->run('(list? (list 2 3 4 5))'), 'list? returns true with single list argument';
    ok !self->run('(list? :foo)'), 'list? returns false with non list argument';
    ok self->run('(list? (list 2 3) (list 3 4))'), 'list? returns true with multiple lists as arguments';
    ok !self->run('(list? (list 2 3) :x (list 3 4))'), 'list? returns false with multiple arguments but one non list';
    throws_ok { $self->run('(list?') } 'Script::SXC::Exception', 'list? throws error when called without arguments';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T200_hashes: Tests {
    my $self = self;

    # creation
    is_deeply self->run('(hash :foo (hash "bar" 23))'), { foo => { bar => 23 } }, 'hash creation';
    is_deeply self->run('(hash 1 2 3 4)'), { 1 => 2, 3 => 4 }, 'hash creation with number sequence';
    is_deeply self->run('(hash)'), {}, 'hash without arguments returns empty hash';
    throws_ok { $self->run('(hash :x)') } 'Script::SXC::Exception', 'hash with odd number of arguments throws error';
    like $@, qr/even/i, 'error message contains "even"';
    like $@, qr/key.+value/i, 'error message contains "key" and then "value"';

    # keys introspection
    is_deeply [sort(@{ self->run('(keys (hash x: 3 y: 17))') })], [qw( x y )], 'keys returns keys of the hash';
    is_deeply self->run('(define foo (hash x: 777)) (keys foo)'), ['x'], 'keys returns keys of hash in variable';
    is_deeply self->run('(keys (hash))'), [], 'keys returns empty list if hash is empty';
    throws_ok { $self->run('(keys)') } 'Script::SXC::Exception', 'keys without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(keys (hash) 3)') } 'Script::SXC::Exception', 'keys with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(keys 23)') } 'Script::SXC::Exception', 'keys with non hash as argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/hash/i, 'error message contains "hash"';

    # values introspection
    is_deeply [sort(@{ self->run('(values (hash x: 3 y: 17))') })], [17, 3], 'values returns list with values of the hash';
    is_deeply self->run('(define foo (hash x: 777)) (values foo)'), [777], 'values returns values of hash in variable';
    is_deeply self->run('(values (hash))'), [], 'values returns empty list if hash is empty';
    throws_ok { $self->run('(values)') } 'Script::SXC::Exception', 'values without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(values (hash) 3)') } 'Script::SXC::Exception', 'values with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(values 23)') } 'Script::SXC::Exception', 'values with non hash as argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/hash/i, 'error message contains "hash"';

    # hash-ref
    is self->run('(hash-ref (hash x: 23 y: 42) :x)'), 23, 'hash-ref returns correct hash value';
    is self->run('(hash-ref (hash) :x)'), undef, 'hash-ref returns undef if key does not exist';
    throws_ok { $self->run('(hash-ref)') } 'Script::SXC::Exception', 'hash-ref without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(hash-ref (hash 2 3))') } 'Script::SXC::Exception', 'hash-ref with missing argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(hash-ref (hash 2 3) 1 2)') } 'Script::SXC::Exception', 'hash-ref with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
    throws_ok { $self->run('(hash-ref 23 7)') } 'Script::SXC::Exception', 'hash-ref with non hash as first argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/hash/i, 'error message contains "hash"';

    # merging hashes
    is_deeply self->run('(merge (hash 2 3) (hash 4 5))'), {2, 3, 4, 5}, 'merge returns new hash with result of two hashes';
    is_deeply self->run('(merge (hash 2 3) (hash 4 5) (hash x: 3))'), {2, 3, 4, 5, 'x', 3}, 'merge returns new hash with result of three hashes';
    throws_ok { $self->run('(merge)') } 'Script::SXC::Exception', 'merge without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(merge (hash 2 3))') } 'Script::SXC::Exception', 'merge with only one argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(merge (hash 2 3) 4 (hash 5 6))') } 'Script::SXC::Exception', 'merge with non hash argument throws error';
    like $@, qr/invalid\s+argument\s+1/i, 'error message contains "invalid argument 1"';
    like $@, qr/hash/i, 'error message contains "hash"';

    # predicate
    ok self->run('(hash? (hash 2 3 4 5))'), 'hash? returns true with single hash argument';
    ok !self->run('(hash? :foo)'), 'hash? returns false with single non hash argument';
    ok self->run('(hash? (hash 2 3) (hash 3 4))'), 'hash? returns true with multiple hashes as arguments';
    ok !self->run('(hash? (hash 2 3) :x (hash 3 4))'), 'hash? returns false with multiple arguments but one non hash';
    throws_ok { $self->run('(hash?') } 'Script::SXC::Exception', 'hash? throws error when called without arguments';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T300_strings: Tests {
    my $self = self;

    # creation
    is self->run('(string)'), '', 'string without arguments returns empty string';
    is self->run('(string "foo")'), 'foo', 'string with single string argument returns string with argument content';
    is self->run('(string "foo " Z: 23)'), 'foo Z23', 'various types combined to single string';

    # interpolation
    is self->run('(let ((x 23) (y (hash n: 7 m: 8))) "foo ${x} bar $(hash-ref y :n) baz")'), 'foo 23 bar 7 baz',
        'interpolation of variables and applications leads to correct result';
}

1;
