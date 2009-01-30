package Script::SXC::Test::Library::Data::Lists;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );


sub T100_creation: Tests {
    my $self = shift;

    is_deeply $self->run('(list 1 (list 2 3) (list (list 4 (list 5))))'), [1, [2, 3], [[4, [5]]]], 'explicit list creation';
    is_deeply $self->run('(list)'), [], 'explicit empty list creation';
    is_deeply $self->run('()'), [], 'implicit empty list creation';
}

sub T120_append: Tests {
    my $self = shift;

    is_deeply $self->run('(append (list 2 3) (list 4 5))'), [2, 3, 4, 5], 'append returns new list with merge of two lists';
    is_deeply $self->run('(append (list 2 3) (list 4 5) (list 3))'), [2, 3, 4, 5, 3], 'append returns new list with merge of three lists';

    throws_ok { $self->run('(append)') } 'Script::SXC::Exception', 'append without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(append (list 2 3))') } 'Script::SXC::Exception', 'append with only one argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(append (list 2 3) 4 (list 5 6))') } 'Script::SXC::Exception', 'append with non list argument throws error';
    like $@, qr/invalid\s+argument\s+1/i, 'error message contains "invalid argument 1"';
    like $@, qr/list/i, 'error message contains "list"';
}

sub T200_head: Tests {
    my $self = shift;

    is $self->run('(head (list 1 2 3))'), 1, 'head without argument returns first element';
    is $self->run('(head (list))'), undef, 'head without argument and with empty list returns undef';

    is_deeply $self->run('(head (list 23 2 3) 1)'), [23], 'head with one as number returns list with one element';
    is_deeply $self->run('(head (list 1 2 3 4) 2)'), [1, 2], 'head with number returns first number of elements';
    is_deeply $self->run('(head (list 1 2 3) 5)'), [1, 2, 3], 'head with number and too small list returns complete list';
    is_deeply $self->run('(head (list) 3)'), [], 'head with number but empty list returns empty list';

    throws_ok { $self->run('(head)') } 'Script::SXC::Exception', 'head without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(head 23)') } 'Script::SXC::Exception', 'head with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';

    throws_ok { $self->run('(head (list 2 3) 4 5)') } 'Script::SXC::Exception', 'head with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
}

sub T210_tail: Tests {
    my $self = shift;

    is_deeply $self->run('(tail (list 1 2 3))'), [2, 3], 'tail without number returns all but first element';
    is_deeply $self->run('(tail (list))'), [], 'tail without number and with empty list returns empty list';
    is_deeply $self->run('(tail (list 1 2 3 4) 2)'), [3, 4], 'tail with number returns number of elements from the end of the list';
    is_deeply $self->run('(tail (list 1 2 3) 5)'), [1, 2, 3], 'tail with number and too small list returns complete list';
    is_deeply $self->run('(tail (list) 3)'), [], 'tail with number but empty list returns empty list';

    throws_ok { $self->run('(tail)') } 'Script::SXC::Exception', 'tail without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(tail 23)') } 'Script::SXC::Exception', 'tail with non list argument throws error';
    like $@, qr/list/i, 'error message contains "list"';

    throws_ok { $self->run('(tail (list 2 3) 4 5)') } 'Script::SXC::Exception', 'tail with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';
}

sub T220_size: Tests {
    my $self = shift;

    is $self->run('(size (list "foo" "bar" "baz"))'), 3, 'size returns correct size of list';
    is $self->run('(size (list))'), 0, 'size returns zero on empty list';

    throws_ok { $self->run('(size)') } 'Script::SXC::Exception', 'size without argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(size (list 2 3) 4)') } 'Script::SXC::Exception', 'size with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';

    throws_ok { $self->run('(size 23)') } 'Script::SXC::Exception', 'size with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';
}

sub T300_index: Tests {
    my $self = shift;

    is $self->run('(last-index (list 1 2 4 5 6 7))'), 5, 'last-index returns last index of list';
    is $self->run('(last-index (list 23))'), 0, 'last-index returns zero with single item list';
    is $self->run('(last-index (list))'), -1, 'last-index returns negative one when list is empty';

    throws_ok { $self->run('(last-index)') } 'Script::SXC::Exception', 'last-index without argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(last-index (list 2 3) 4)') } 'Script::SXC::Exception', 'last-index with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';

    throws_ok { $self->run('(last-index 23)') } 'Script::SXC::Exception', 'last-index with non list argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';
}

sub T400_ref: Tests {
    my $self = shift;

    is $self->run('(list-ref (list 2 3 4) 1)'), 3, 'list-ref returns correct list element';
    is $self->run('(list-ref (list) 3)'), undef, 'list-ref returns undef if element does not exist';

    throws_ok { $self->run('(list-ref)') } 'Script::SXC::Exception', 'list-ref without arguments throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(list-ref (list 2 3))') } 'Script::SXC::Exception', 'list-ref with missing argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(list-ref (list 2 3) 1 2)') } 'Script::SXC::Exception', 'list-ref with too many arguments throws error';
    like $@, qr/too many/i, 'error message contains "too many"';

    throws_ok { $self->run('(list-ref 23 7)') } 'Script::SXC::Exception', 'list-ref with non list as first argument throws error';
    like $@, qr/argument/i, 'error message contains "argument"';
    like $@, qr/list/i, 'error message contains "list"';
}

sub T500_predicate: Tests {
    my $self = shift;

    ok $self->run('(list? (list 2 3 4 5))'), 'list? returns true with single list argument';
    ok !$self->run('(list? :foo)'), 'list? returns false with non list argument';
    ok $self->run('(list? (list 2 3) (list 3 4))'), 'list? returns true with multiple lists as arguments';
    ok !$self->run('(list? (list 2 3) :x (list 3 4))'), 'list? returns false with multiple arguments but one non list';

    throws_ok { $self->run('(list?') } 'Script::SXC::Exception', 'list? throws error when called without arguments';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T600_map: Tests {
    my $self = shift;

    is_deeply $self->run('(map (list 2 3 4) (λ n n))'), [[2], [3], [4]], 'simple map iterates over list correctly';
    is_deeply $self->run('(map (list 2 3 4) ++)'), [3, 4, 5], 'map called on builtin returns correct list';
    is_deeply $self->run('(map (list :x :y) (hash x: 3 y: 4))'), [3, 4], 'hash application with keyword list works';
    is_deeply $self->run('(map (list (hash :x 1 :y 2) (hash :x 3 :y 4)) :y)'), [2, 4], 'keyword application with hash lists works';

    throws_ok { $self->run('(map (list 2 3))') } 'Script::SXC::Exception', 'map with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/map/, 'error message contains "map"';

    throws_ok { $self->run('(map (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'map with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/map/, 'error message contains "map"';

    throws_ok { $self->run('(map (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'map with non list throws exception';
    like $@, qr/map/, 'error message contains "map"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/first argument/i, 'error message contains "first argument"';
}

sub T610_grep: Tests {
    my $self = shift;

    is_deeply $self->run('(grep (list 3 8 5 0 7 9) (λ (n) (< n 6)))'), [3, 5, 0], 'simple grep returns correct result';
    is_deeply $self->run('(grep (list 1 0 :x "" -1 #f (list)) false?)'), [0, '', undef], 'grep with builtin returns correct list';
    is_deeply $self->run('(grep (list "x" "y" "z") (hash x: -1 y: 0 z: 1))'), [qw( x z )], 'grep on hash operator works';
    is_deeply $self->run('(grep (list {x: 0 y: 1} {x: 1 y: 0}) :x)'), [{x => 1, y => 0}], 'invocant switch in grep works';

    throws_ok { $self->run('(grep (list 2 3))') } 'Script::SXC::Exception', 'grep with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/grep/, 'error message contains "grep"';

    throws_ok { $self->run('(grep (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'grep with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/grep/, 'error message contains "grep"';

    throws_ok { $self->run('(grep (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'grep with non list throws exception';
    like $@, qr/grep/, 'error message contains "grep"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/first argument/i, 'error message contains "first argument"';
}

sub T620_count: Tests {
    my $self = shift;

    is $self->run('(count (list 3 8 5 0 7 9) (λ (n) (< n 6)))'), 3, 'simple count returns correct result';
    is $self->run('(count (list 1 0 :x "" -1 #f (list)) false?)'), 3, 'count with builtin returns correct list';
    is $self->run('(count (list "x" "y" "z") (hash x: -1 y: 0 z: 1))'), 2, 'count on hash operator works';
    is $self->run('(count (list {x: 0 y: 1} {x: 1 y: 0} {x: 3 y: -1}) :x)'), 2, 'invocant switch in count works';
    is $self->run('(count (list 1 2 3 4) (λ (n) (> 0 n)))'), 0, 'count without match returns zero';

    throws_ok { $self->run('(count (list 2 3))') } 'Script::SXC::Exception', 'count with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/count/, 'error message contains "count"';

    throws_ok { $self->run('(count (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'count with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/count/, 'error message contains "count"';

    throws_ok { $self->run('(count (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'count with non list throws exception';
    like $@, qr/count/, 'error message contains "count"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/first argument/i, 'error message contains "first argument"';
}

sub T630_predicate_any: Tests {
    my $self = shift;

    is $self->run('(any? (list 3 8 5 0 7 9) (λ (n) (< n 6)))'), 1, 'simple true any? returns correct result';
    is $self->run('(any? (list 8 7 9) (λ (n) (< n 6)))'), undef, 'simple false any? returns correct result';
    is $self->run('(any? (list 0 "" #f) false?)'), 1, 'true any? with builtin returns correct result';
    is $self->run('(any? (list 1 "foo" -1) false?)'), undef, 'false any? with builtin returns correct result';
    is $self->run('(any? (list "x" "y" "z") (hash x: -1 y: 0 z: 1))'), 1, 'true any? on hash operator works';
    is $self->run('(any? (list "x" "y" "z") (hash x: "" y: 0 z: #f))'), undef, 'false any? on hash operator works';
    is $self->run('(any? (list {x: 0 y: 1} {x: 1 y: 0}) :x)'), 1, 'invocant switch in true any? works';
    is $self->run('(any? (list {x: 0 y: 1} {x: "" y: 0}) :x)'), undef, 'invocant switch in false any? works';

    throws_ok { $self->run('(any? (list 2 3))') } 'Script::SXC::Exception', 'any? with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/any\?/, 'error message contains "any?"';

    throws_ok { $self->run('(any? (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'any? with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/any\?/, 'error message contains "any?"';

    throws_ok { $self->run('(any? (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'any? with non list throws exception';
    like $@, qr/any\?/, 'error message contains "any?"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/first argument/i, 'error message contains "first argument"';
}

sub T631_predicate_all: Tests {
    my $self = shift;

    is $self->run('(all? (list 1 2 3 4 "foo") true?)'), 1, 'all? returns true for all true values';
    is $self->run('(all? (list 4) true?)'), 1, 'all? returns true for single true value list';
    is $self->run('(all? (list 1 2 3 0 4) true?)'), undef, 'all? returns undefined value if test is negative on one element';
    is $self->run('(all? (list #f 0 "") true?)'), undef, 'all? returns undefined value on all negative elements';
    is $self->run('(all? (list :x :y)    { x: 2 y: 1 z: 0 })'), 1, 'true all? hash application returns true';
    is $self->run('(all? (list :x :y :z) { x: 2 y: 1 z: 0 })'), undef, 'false all? hash application returns undefined value';
    is $self->run('(all? (list { x: 3 } { x: 5 }) :x)'), 1, 'true all? swapped invocant hash application returns true';
    is $self->run('(all? (list { x: 3 } { x: 0 }) :x)'), undef, 'false all? swapped invocant hash application returns undefined value';
    is $self->run('(all? (list 0 1 2)   (list 3 2 1 0))'), 1, 'true all? list application returns true';
    is $self->run('(all? (list 0 1 2 3) (list 3 2 1 0))'), undef, 'false all? list application returns undefined value';

    throws_ok { $self->run('(all? (list 2 3))') } 'Script::SXC::Exception', 'all? with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/all\?/, 'error message contains "all?"';

    throws_ok { $self->run('(all? (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'all? with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/all\?/, 'error message contains "all?"';

    throws_ok { $self->run('(all? (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'all? with non list throws exception';
    like $@, qr/all\?/, 'error message contains "all?"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/first argument/i, 'error message contains "first argument"';
}

sub T632_predicate_none: Tests {
    my $self = shift;

    is $self->run('(none? (list 1 2 3 4 "foo") false?)'), 1, 'none? returns true for all true values';
    is $self->run('(none? (list 4) false?)'), 1, 'none? returns true for single true value list';
    is $self->run('(none? (list 1 2 3 0 4) false?)'), undef, 'none? returns undefined value if test is negative on one element';
    is $self->run('(none? (list #f 0 "") false?)'), undef, 'none? returns undefined value on all negative elements';
    is $self->run('(none? (list :x :y)    { x: 0 y: "" z: 23 })'), 1, 'true none? hash application returns true';
    is $self->run('(none? (list :x :y :z) { x: 0 y: "" z: 23 })'), undef, 'false none? hash application returns undefined value';
    is $self->run('(none? (list { x: 0 } { x: "" }) :x)'), 1, 'true none? swapped invocant hash application returns true';
    is $self->run('(none? (list { x: 0 } { x: 23 }) :x)'), undef, 'false none? swapped invocant hash application returns undefined value';
    is $self->run('(none? (list 0 1 2)   (list "" #f 0 23))'), 1, 'true none? list application returns true';
    is $self->run('(none? (list 0 1 2 3) (list "" #f 0 23))'), undef, 'false none? list application returns undefined value';

    throws_ok { $self->run('(none? (list 2 3))') } 'Script::SXC::Exception', 'none? with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/none\?/, 'error message contains "none?"';

    throws_ok { $self->run('(none? (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'none? with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/none\?/, 'error message contains "none?"';

    throws_ok { $self->run('(none? (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'none? with non list throws exception';
    like $@, qr/none\?/, 'error message contains "none?"';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/first argument/i, 'error message contains "first argument"';
}

sub T640_predicate_pair: Tests {
    my $self = shift;

    is $self->run('(pair? (list 2 3))'), 1, 'pair? returns true on two item list';
    is $self->run('(pair? (list 2))'), undef, 'pair? returns undefined value on single item list';
    is $self->run('(pair? (list 2 3 4))'), undef, 'pair? returns undefined value on three item list';
    is $self->run('(pair? { x: 23 })'), undef, 'pair? returns undefined value on hash';
    is $self->run('(pair? (list 2 3) (list 4 5))'), 1, 'pair? returns true on multiple pairs';
    is $self->run('(pair? (list 2 3) (list 3 4 5))'), undef, 'pair? returns true on multiple pairs and non pairs';

    throws_ok { $self->run('(pair?)') } 'Script::SXC::Exception', 'pair? without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/pair\?/, 'error message contains "pair?"';
}

sub T650_for_iteration: Tests {
    my $self = shift;

    is_deeply $self->run('(let [(r ())] (for (list 1 2 3) [-> (set! r (append r (list _)))]))'), [1, 2, 3],
        'for iteration over list returns correct result';
    is_deeply $self->run('(let [(r ())] (for (range 1 16 step: [-> (* _ 2)]) [-> (set! r (append r (list _)))]))'), [1, 2, 4, 8, 16],
        'for iteration over range returns correct result';

    throws_ok { $self->run('(for (list 2 3))') } 'Script::SXC::Exception', 'for with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/for/, 'error message contains "for"';

    throws_ok { $self->run('(for (list 2 3) (λ n n) (λ m m))') } 'Script::SXC::Exception', 'for with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/for/, 'error message contains "for"';

    throws_ok { $self->run('(for (hash x: 23) (λ x x))') } 'Script::SXC::Exception', 'for with non list throws exception';
    like $@, qr/list/i, 'error message contains "list"';
}

sub T700_zip: Tests {
    my $self = shift;

    is_deeply $self->run('(zip + (list 3 4) (list 5 6))'), [8, 10], 'zipping two lists with builtin returns correct result';
    is_deeply $self->run('(zip apply (list + -) (list (list 10 5) (list 30 13)))'), [15, 17], 'apply zip trick returns correct result';
    is_deeply $self->run('(zip (λ l l) (list 4 5) (list 7 8))'), [[4, 7], [5, 8]], 'zipping two lists with lambda returns correct result';
    is_deeply $self->run('(zip + (list 3 4 5) (list 6 7 8) (list 7 8 9))'), [16, 19, 22], 'zippint three lists returns correct result';

    throws_ok { $self->run('(zip + (list 2 3))') } 'Script::SXC::Exception', 'zip with two arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/zip/, 'error message contains "zip"';

    throws_ok { $self->run('(zip #f (list 2 3) (list 4 5))') } 'Script::SXC::Exception', 'zip with invalid applicant throws exception';
    like $@, qr/appl/i, 'error message contains "appl"';

    throws_ok { $self->run('(zip + { x: 3 } (list 4 5))') } 'Script::SXC::Exception', 'zip with non list throws exception';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/zip/, 'error message contains "zip"';
    like $@, qr/argument 1/i, 'error message contains "argument 1"';
}

sub T800_setter: Tests {
    my $self = shift;

    is_deeply $self->run('(begin (define ls (list 2 3 4)) (define res (set! (list-ref ls 1) 23)) (list res ls))'), 
        [23, [2, 23, 4]],
        'explicit list-ref setter works';

    throws_ok { $self->run('(set! (list-ref (list 2 3)) 23)') } 'Script::SXC::Exception', 
        'missing list-ref index throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/list-ref/, 'error message contains "list-ref"';

    throws_ok { $self->run('(set! (list-ref (list 2 3) 1 2) 23)') } 'Script::SXC::Exception', 
        'too many list-ref setter arguments with expression throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/list-ref/, 'error message contains "list-ref"';

    throws_ok { $self->run('(set! (list-ref (list 2 3) 4))') } 'Script::SXC::Exception', 
        'missing list-ref expression with index throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/set!/, 'error message contains "set!"';

    throws_ok { $self->run('(set! (list-ref (list 2 3) 1) 23 12)') } 'Script::SXC::Exception', 
        'too many list-ref setter expressions with index throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/set!/, 'error message contains "set!"';

    throws_ok { $self->run('(set! (list-ref (list 2 3)) 23 12)') } 'Script::SXC::Exception', 
        'too many list-ref setter expressions without index throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/set!/, 'error message contains "set!"';

    throws_ok { $self->run('(set! (list-ref (list 2 3) 4 17))') } 'Script::SXC::Exception', 
        'missing list-ref expression with too many expressions throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/set!/, 'error message contains "set!"';
}

sub T900_nested_list_proc: Tests {
    my $self = shift;

    is_deeply $self->run('(grep (map (grep (list 1 2 3 4 5 6) odd?) (λ (x) { x: x lt2: (> x 2) })) :lt2)'),
              [{ x => 3, lt2 => 1 }, { x => 5, lt2 => 1 }],
              'nested map and grep work and return correct result';
}

1;
