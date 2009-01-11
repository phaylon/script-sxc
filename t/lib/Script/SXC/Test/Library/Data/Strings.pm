package Script::SXC::Test::Library::Data::Strings;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );
use self;

sub T050_creation: Tests {

    is self->run('(string)'), '', 'string without arguments returns empty string';
    is self->run('(string "foo")'), 'foo', 'string with single string argument returns string with argument content';
    is self->run('(string "foo " Z: 23)'), 'foo Z23', 'various types combined to single string';
}

sub T100_interpolation: Tests {

    is self->run('(let ((x 23) (y (hash n: 7 m: 8))) "foo ${x} bar $(hash-ref y :n) baz")'), 'foo 23 bar 7 baz',
        'interpolation of variables and applications leads to correct result';
}

sub T200_predicate: Tests {
    my $self = self;

    is self->run('(string? "foo" 23)'), 1, 'string predicate returns true on strings and numbers';
    is self->run('(string? "foo" #f)'), undef, 'string predicate returns false on undefined value';
    is self->run('(string? "foo" (list 2 3))'), undef, 'string predicate returns false on reference';

    throws_ok { $self->run('(string?)') } 'Script::SXC::Exception', 'string predicate without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/string\?/, 'error message contains "string?"';
}

sub T300_equality: Tests {
    my $self = self;

    is self->run('(eq? "a" "a")'), 1, 'string equality with two equal elements returns true';
    is self->run('(eq? "a" "a" "a")'), 1, 'string equality with more than two equal elements returns true';
    is self->run('(eq? "a" "a" "b")'), undef, 'string equality with non-equal values returns undefined value';

    throws_ok { $self->run('(eq? "a")') } 'Script::SXC::Exception', 'string equality with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/eq\?/, 'error message contains "eq?"';
}

sub T350_non_equality: Tests {
    my $self = self;

    is self->run('(ne? "foo" "bar")'), 1, 'string non-equality with two non equal strings returns true';
    is self->run('(ne? "foo" "foo")'), undef, 'string non-equality with two equal strings returns false';
    is self->run('(ne? "foo" "bar" "foo")'), undef, 'string non-equality with some equal strings returns false';

    throws_ok { $self->run('(ne? "a")') } 'Script::SXC::Exception', 'string non-equality with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/ne\?/, 'error message contains "ne?"';
}

sub T400_less_than: Tests {
    my $self = self;

    is self->run('(lt? "a" "b")'), 1, 'true less-than with two arguments works';
    is self->run('(lt? "a" "b" "c")'), 1, 'true less-than with more than two arguments works';
    is self->run('(lt? "b" "a")'), undef, 'false less-than with two values works';
    is self->run('(lt? "a" "b" "a")'), undef, 'false less-than with more than two values works';
    is self->run('(lt? "a" "b" "b")'), undef, 'two equal values are wrong in the eyes of less-than';

    throws_ok { $self->run('(lt? "a")') } 'Script::SXC::Exception', 'less-than with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/lt\?/, 'error message contains "lt?"';
}

sub T410_greater_than: Tests {
    my $self = self;

    is self->run('(gt? "b" "a")'), 1, 'true greater-than with two arguments works';
    is self->run('(gt? "c" "b" "a")'), 1, 'true greater-than with more than two arguments works';
    is self->run('(gt? "a" "b")'), undef, 'false greater-than with two values works';
    is self->run('(gt? "d" "c" "b" "c")'), undef, 'false greater-than with more than two values works';
    is self->run('(gt? "b" "a" "a")'), undef, 'two equal values are wrong in the eyes of greater-than';

    throws_ok { $self->run('(gt? "a")') } 'Script::SXC::Exception', 'greater-than with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/gt\?/, 'error message contains "gt?"';
}

sub T420_less_than_or_equal: Tests {
    my $self = self;

    is self->run('(le? "a" "b")'), 1, 'true less-than-or-equal with two arguments works';
    is self->run('(le? "a" "b" "c")'), 1, 'true less-than-or-equal with more than two arguments works';
    is self->run('(le? "b" "a")'), undef, 'false less-than-or-equal with two values works';
    is self->run('(le? "a" "b" "a")'), undef, 'false less-than-or-equal with more than two values works';
    is self->run('(le? "a" "b" "b")'), 1, 'two equal values are true in the eyes of less-than-or-equal';

    throws_ok { $self->run('(le? "a")') } 'Script::SXC::Exception', 'less-than-or-equal with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/le\?/, 'error message contains "le?"';
}

sub T430_greater_than_or_equal: Tests {
    my $self = self;

    is self->run('(ge? "b" "a")'), 1, 'true greater-than-or-equal with two arguments works';
    is self->run('(ge? "c" "b" "a")'), 1, 'true greater-than-or-equal with more than two arguments works';
    is self->run('(ge? "a" "b")'), undef, 'false greater-than-or-equal with two values works';
    is self->run('(ge? "d" "c" "b" "c")'), undef, 'false greater-than-or-equal with more than two values works';
    is self->run('(ge? "b" "a" "a")'), 1, 'two equal values are true in the eyes of greater-than-or-equal';

    throws_ok { $self->run('(ge? "a")') } 'Script::SXC::Exception', 'greater-than-or-equal with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/ge\?/, 'error message contains "ge?"';
}

sub T500_join: Tests {
    my $self = self;

    is self->run('(join "," (list 1 2 3))'), '1,2,3', 'join with three elements returns correct string';
    is self->run('(join "," (list))'), '', 'join with empty list returns empty string';

    throws_ok { $self->run('(join ",")') } 'Script::SXC::Exception', 'join with only one argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/join/, 'error message contains "join"';

    throws_ok { $self->run('(join "," 2 3)') } 'Script::SXC::Exception', 'join with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/join/, 'error message contains "join"';

    throws_ok { $self->run('(join "," 23)') } 'Script::SXC::Exception', 'join with non list as second argument throws exception';
    like $@, qr/list/i, 'error message contains "list"';
    like $@, qr/join/, 'error message contains "join"';
}

sub T520_sprintf: Tests {
    my $self = self;

    is self->run('(sprintf "[%03d:%s]" 23 :foo)'), '[023:foo]', 'standard sprintf usage returns correct result';
    is self->run('(sprintf (join ", " (list "%s" "%s")) :foo :bar)'), 'foo, bar', 'sprintf format via call returns correct result';

    throws_ok { $self->run('(sprintf "foo")') } 'Script::SXC::Exception', 'sprintf with only format argument throws error';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/sprintf/, 'error message contains "sprintf"';

    is_deeply self->run('(list (sprintf "[%s.%s]" 17))'), ["[17.]"], 'sprintf ignores missing values';
    is_deeply self->run('(list (sprintf "[%s]" 3 4))'), ["[3]"], 'sprintf ignores additional values';
}



1;
