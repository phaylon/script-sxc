package Script::SXC::Test::Library::Data::Numbers;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );

sub T100_addition: Tests {
    my $self = shift;

    is $self->run('(+)'), 0, 'addition without arguments returns 0';
    is $self->run('(+ 3)'), 3, 'addition with one argument returns argument';
    is $self->run('(+ 2 3 4)'), 9, 'addition with multiple arguments works';
    is $self->run('(+ -1 1)'), 0, 'addition with negatives works';
}

sub T110_subtraction: Tests {
    my $self = shift;

    is $self->run('(-)'), 0, 'subtraction without arguments returns 0';
    is $self->run('(- 3)'), 3, 'subtraction with one argument returns argument';
    is $self->run('(- 2 3 4)'), -5, 'subtraction with multiple arguments works';
    is $self->run('(- -1 1)'), -2, 'subtraction with negatives works';
}

sub T120_multiplication: Tests {
    my $self = shift;

    is $self->run('(*)'), 0, 'multiplication without arguments returns 0';
    is $self->run('(* 3)'), 3, 'multiplication with one argument returns argument';
    is $self->run('(* 2 3 4)'), 24, 'multiplication with multiple arguments works';
    is $self->run('(* -2 2)'), -4, 'multiplication with negatives works';
}

sub T130_division: Tests {
    my $self = shift;

    is $self->run('(/)'), 0, 'division without arguments returns 0';
    is $self->run('(/ 3)'), 3, 'division with one argument returns argument';
    is $self->run('(/ 200 2 4)'), 25, 'division with multiple arguments works';
    is $self->run('(/ -20 2)'), -10, 'division with negatives works';

    throws_ok { $self->run('(/ 10 0)') } 'Script::SXC::Exception::ArgumentError',
        'division by zero throws argument error';
    like $@, qr/division by zero/i, 'error message contains "division by zero"';
    is $@->type, 'division_by_zero', 'error type is "division_by_zero"';
}

sub T200_decrement: Tests {
    my $self = shift;

    is $self->run('(-- 23)'), 22, 'decrement works';

    throws_ok { $self->run('(--)') } 'Script::SXC::Exception', 'decrement without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/--/, 'error message contains "--"';

    throws_ok { $self->run('(-- 2 3)') } 'Script::SXC::Exception', 'decrement with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/--/, 'error message contains "--"';
}

sub T210_increment: Tests {
    my $self = shift;

    is $self->run('(++ 23)'), 24, 'increment works';

    throws_ok { $self->run('(++)') } 'Script::SXC::Exception', 'increment without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/\+\+/, 'error message contains "++"';

    throws_ok { $self->run('(++ 2 3)') } 'Script::SXC::Exception', 'increment with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/\+\+/, 'error message contains "++"';
}

sub T300_equality: Tests {
    my $self = shift;

    is $self->run('(== 5 5)'), 1, 'equality with two equal elements returns true';
    is $self->run('(== 5 5 5)'), 1, 'equality with more than two equal elements returns true';
    is $self->run('(== 5 5 6)'), undef, 'equality with non-equal values returns undefined value';

    throws_ok { $self->run('(== 5)') } 'Script::SXC::Exception', 'equality with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/==/, 'error message contains "=="';

    is $self->run('(= 5 5)'), 1, 'equality alias with two equal elements returns true';
    is $self->run('(= 5 6)'), undef, 'equality alias with two non-equal elements returns an undefined value';

    throws_ok { $self->run('(= 5)') } 'Script::SXC::Exception', 'equality alias with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T310_non_equality: Tests {
    my $self = shift;

    is $self->run('(!= 4 5)'), 1, 'non-equality with two non equal elements returns true';
    is $self->run('(!= 4 4)'), undef, 'non-equality with two equal elements returns false';
    is $self->run('(!= 4 5 4)'), undef, 'non-equality with some equal elements returns false';

    throws_ok { $self->run('(!= 3)') } 'Script::SXC::Exception', 'non-equality with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/!=/, 'error message contains "!="';
}

sub T350_smaller_than: Tests {
    my $self = shift;

    is $self->run('(< 2 3)'), 1, 'true smaller-than with two arguments works';
    is $self->run('(< 2 3 6 7)'), 1, 'true smaller-than with more than two arguments works';
    is $self->run('(< 3 2)'), undef, 'false smaller-than with two values works';
    is $self->run('(< 2 3 5 4)'), undef, 'false smaller-than with more than two values works';
    is $self->run('(< 2 3 3)'), undef, 'two equal values are wrong in the eyes of smaller-than';

    throws_ok { $self->run('(< 2)') } 'Script::SXC::Exception', 'smaller-than with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/</, 'error message contains "<"';
}

sub T360_greater_than: Tests {
    my $self = shift;

    is $self->run('(> 3 2)'), 1, 'true greater-than with two arguments works';
    is $self->run('(> 9 7 5 3)'), 1, 'true greater-than with more than two arguments works';
    is $self->run('(> 2 3)'), undef, 'false greater-than with two values works';
    is $self->run('(> 8 6 4 5)'), undef, 'false greater-than with more than two values works';
    is $self->run('(> 4 3 3)'), undef, 'two equal values are wrong in the eyes of greater-than';

    throws_ok { $self->run('(> 2)') } 'Script::SXC::Exception', 'greater-than with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/>/, 'error message contains ">"';
}

sub T370_smaller_than_or_equal: Tests {
    my $self = shift;

    is $self->run('(<= 2 3)'), 1, 'true smaller-than-or-equal with two arguments works';
    is $self->run('(<= 2 3 6 7)'), 1, 'true smaller-than-or-equal with more than two arguments works';
    is $self->run('(<= 3 2)'), undef, 'false smaller-than-or-equal with two values works';
    is $self->run('(<= 2 3 5 4)'), undef, 'false smaller-than-or-equal with more than two values works';
    is $self->run('(<= 2 3 3)'), 1, 'two equal values are true in the eyes of smaller-than-or-equal';

    throws_ok { $self->run('(<= 2)') } 'Script::SXC::Exception', 'smaller-than-or-equal with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/<=/, 'error message contains "<="';
}

sub T380_greater_than_or_equal: Tests {
    my $self = shift;

    is $self->run('(>= 3 2)'), 1, 'true greater-than-or-equal with two arguments works';
    is $self->run('(>= 9 7 5 3)'), 1, 'true greater-than-or-equal with more than two arguments works';
    is $self->run('(>= 2 3)'), undef, 'false greater-than-or-equal with two values works';
    is $self->run('(>= 8 6 4 5)'), undef, 'false greater-than-or-equal with more than two values works';
    is $self->run('(>= 4 3 3)'), 1, 'two equal values are true in the eyes of greater-than-or-equal';

    throws_ok { $self->run('(>= 2)') } 'Script::SXC::Exception', 'greater-than-or-equal with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/>=/, 'error message contains ">="';
}

sub T400_absolute: Tests {
    my $self = shift;

    is $self->run('(abs -23)'), 23, 'absolute of -23 is 23';
    is $self->run('(abs 23)'), 23, 'absolute of 23 is 23';

    throws_ok { $self->run('(abs)') } 'Script::SXC::Exception', 'absolute without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/abs/, 'error message contains "abs"';

    throws_ok { $self->run('(abs 2 3)') } 'Script::SXC::Exception', 'absolute with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/abs/, 'error message contains "abs"';
}

sub T500_modulus: Tests {
    my $self = shift;

    is $self->run('(mod 10 2)'), 0, 'modulus without rest returns correct result';
    is $self->run('(mod 10 4)'), 2, 'modulus with rest returns correct result';

    throws_ok { $self->run('(mod 10)') } 'Script::SXC::Exception', 'modulus with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/mod/, 'error message contains "mod"';

    throws_ok { $self->run('(mod 10 4 2)') } 'Script::SXC::Exception', 'modulus with more than two arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/mod/, 'error message contains "mod"';
}

sub T550_even: Tests {
    my $self = shift;

    is $self->run('(even? 10)'), 1, 'even? with even value returns true';
    is $self->run('(even? 11)'), undef, 'even? with odd value returns undefined value';
    is $self->run('(even? 2 4 6 8)'), 1, 'even? with multiple even values returns true';
    is $self->run('(even? 2 4 7 8)'), undef, 'even? with multiple even but one odd value returns undefined value';

    throws_ok { $self->run('(even?)') } 'Script::SXC::Exception', 'even? without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/even\?/, 'error message contains "even?"';
}

sub T560_odd: Tests {
    my $self = shift;

    is $self->run('(odd? 10)'), undef, 'odd? with even value returns undefined value';
    is $self->run('(odd? 11)'), 1, 'odd? with odd value returns true';
    is $self->run('(odd? 1 3 7 9)'), 1, 'odd? with multiple odd values returns true';
    is $self->run('(odd? 1 3 6 9)'), undef, 'odd? with multiple odd but one even value returns undefined value';

    throws_ok { $self->run('(odd?)') } 'Script::SXC::Exception', 'odd? without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/odd\?/, 'error message contains "odd?"';
}

sub T600_min: Tests {
    my $self = shift;

    is $self->run('(min 9 3 8)'), 3, 'min returns lowest number';
    is $self->run('(min 7 7 7)'), 7, 'min returns lowest number with equals';

    throws_ok { $self->run('(min)') } 'Script::SXC::Exception', 'min without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/min/, 'error message contains "min"';
}

sub T610_max: Tests {
    my $self = shift;

    is $self->run('(max 9 3 8)'), 9, 'max returns highest number';
    is $self->run('(max 7 7 7)'), 7, 'max returns highest number with equals';

    throws_ok { $self->run('(max)') } 'Script::SXC::Exception', 'max without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/max/, 'error message contains "max"';
}

sub T650_sqrt: Tests {
    my $self = shift;

    is $self->run('(sqrt 25)'), 5, 'squareroot works';

    throws_ok { $self->run('(sqrt)') } 'Script::SXC::Exception', 'sqrt with no arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/sqrt/, 'error message contains "sqrt"';

    throws_ok { $self->run('(sqrt 2 3)') } 'Script::SXC::Exception', 'sqrt with two arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/sqrt/, 'error message contains "sqrt"';
}

1;
