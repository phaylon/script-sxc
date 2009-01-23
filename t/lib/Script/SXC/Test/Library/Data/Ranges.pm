package Script::SXC::Test::Library::Data::Ranges;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );
use self;

use constant RangeClass => 'Script::SXC::Runtime::Range';

sub T100_only_end: Tests {

    #my $range = self->run('(range 50');
    isa_ok my $range = self->run('(range 50)'), RangeClass;
    is $range->start_at, 0, 'implicit starting position is correct';
    is $range->stop_at, 50, 'explicit end position is correct';
    is_deeply [@{ $range }], [0 .. 50], 'list overloading returns correct result';

    is_deeply self->run('(range 4)'), [0 .. 4], 'constant range below 32 returns list';
    isa_ok self->run('(range 3 step: 1)'), RangeClass, 'constant range with option result';

    is_deeply [@{ self->run('(range -5)') }], [], 'negative range returns empty list';
}

sub T120_start_and_end: Tests {

    #my $range = self->run('(range 1 50)');
    isa_ok my $range = self->run('(range 1 50)'), RangeClass;
    is $range->start_at, 1, 'explicit starting position is correct';
    is $range->stop_at, 50, 'explicit end position is correct';
    is_deeply [@{ $range }], [1 .. 50], 'list overloading returns correct result';

    is_deeply self->run('(range 1 4)'), [1 .. 4], 'constant range below 32 returns list';
    isa_ok self->run('(range 1 3 step: 1)'), RangeClass, 'constant range with option result';

    is_deeply [@{ self->run('(range 2 -5)') }], [], 'negative range returns empty list';
}

sub T200_number_step: Tests {

    is_deeply self->run('(apply list (range 10 step: 2))'), [0, 2, 4, 6, 8, 10], 'numerical stepping returns correct result';
    is_deeply self->run('(apply list (range -3 7 step: 3))'), [-3, 0, 3, 6], 'numerical stepping with not-reached endpoint';
}

sub T220_code_step: Tests {

    is_deeply self->run('(apply list (range 10 step: (-> (+ _ 3))))'), [0, 3, 6, 9], 'code stepping returns correct result';
    is_deeply self->run('(apply list (range 1 20 step: (-> (* _ 2))))'), [1, 2, 4, 8, 16], 'code stepping with explicit start index';

    is_deeply self->run('(apply list (range 20 step: (-> (if (> _ 10) #f (+ _ 2)))))'), [0, 2, 4, 6, 8, 10, 12],
        'code stepper can break iteration by returning undefined value';
}

sub T666_errors: Tests {
    my $self = self;

    throws_ok { $self->run('(range)') } 'Script::SXC::Exception', 'range without arguments throws exception';
    like $@, qr/range/, 'error message contains "range"';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(range 1 2 3 4 5)') } 'Script::SXC::Exception', 'range with more than four arguments throws exception';
    like $@, qr/range/, 'error message contains "range"';
    like $@, qr/too\s+many/i, 'error message contains "too many"';

    throws_ok { $self->run('(range 1 2 3)') } 'Script::SXC::Exception::ArgumentError', 
        'range with too many indices throws exception';
    like $@, qr/range/, 'error message contains "range"';
    like $@, qr/indices/i, 'error message contains "indices"';

    throws_ok { $self->run('(range 2 3 foo:)') } 'Script::SXC::Exception::ArgumentError', 
        'range with missing option value and two indices throws exception';
    like $@, qr/range/, 'error message contains "range"';
    like $@, qr/options/i, 'error message contains "options"';

    throws_ok { $self->run('(range 3 foo:)') } 'Script::SXC::Exception::ArgumentError', 
        'range with missing option value and one index throws exception';
    like $@, qr/range/, 'error message contains "range"';
    like $@, qr/options/i, 'error message contains "options"';

    throws_ok { $self->run('(range 7 fnord: 8)') } 'Script::SXC::Exception::ArgumentError', 
        'invalid range option throws exception';
    like $@, qr/range/, 'error message contains "range"';
    like $@, qr/option/i, 'error message contains "option"';
    like $@, qr/fnord/, 'error message contains invalid option';
}

1;
