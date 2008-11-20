package Script::SXC::Test::Library::Core;
use strict;
use parent 'Script::SXC::Test::Library';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );
use self;

sub T100_lists: Tests {

    # creation
    is_deeply self->run('(list 1 (list 2 3) (list (list 4 (list 5))))'), [1, [2, 3], [[4, [5]]]], 'explicit list creation';

    # head
    is self->run('(head (list 1 2 3))'), 1, 'head without argument returns first element';
    is self->run('(head (list))'), undef, 'head without argument and with empty list returns undef';
    is_deeply self->run('(head (list 1 2 3 4) 2)'), [1, 2], 'head with number returns first number of elements';
    is_deeply self->run('(head (list 1 2 3) 5)'), [1, 2, 3], 'head with number and too small list returns complete list';
    is_deeply self->run('(head (list) 3)'), [], 'head with number but empty list returns empty list';

    # tail
    is_deeply self->run('(tail (list 1 2 3))'), [2, 3], 'tail without number returns all but first element';
    is_deeply self->run('(tail (list))'), [], 'tail without number and with empty list returns empty list';
    is_deeply self->run('(tail (list 1 2 3 4) 2)'), [3, 4], 'tail with number returns number of elements from the end of the list';
    is_deeply self->run('(tail (list 1 2 3) 5)'), [1, 2, 3], 'tail with number and too small list returns complete list';
    is_deeply self->run('(tail (list) 3)'), [], 'tail with number but empty list returns empty list';

    # size
    is self->run('(size (list "foo" "bar" "baz"))'), 3, 'size returns correct size of list';
    is self->run('(size (list))'), 0, 'size returns zero on empty list';

    # last-index
    is self->run('(last-index (list 1 2 4 5 6 7))'), 5, 'last-index returns last index of list';
    is self->run('(last-index (list 23))'), 0, 'last-index returns zero with single item list';
    is self->run('(last-index (list))'), -1, 'last-index returns negative one when list is empty';
}

sub T200_hashes: Tests {

    # creation
    is_deeply self->run('(hash :foo (hash "bar" 23))'), { foo => { bar => 23 } }, 'hash creation';
}

1;
