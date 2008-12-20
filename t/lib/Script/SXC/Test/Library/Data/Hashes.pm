package Script::SXC::Test::Library::Data::Hashes;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );
use self;

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

1;
