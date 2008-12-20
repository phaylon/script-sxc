package Script::SXC::Test::Library::Data::Strings;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );
use self;

sub T300_strings: Tests {
    my $self = self;

    # creation
    is self->run('(string)'), '', 'string without arguments returns empty string';
    is self->run('(string "foo")'), 'foo', 'string with single string argument returns string with argument content';
    is self->run('(string "foo " Z: 23)'), 'foo Z23', 'various types combined to single string';

    # interpolation
    is self->run('(let ((x 23) (y (hash n: 7 m: 8))) "foo ${x} bar $(hash-ref y :n) baz")'), 'foo 23 bar 7 baz',
        'interpolation of variables and applications leads to correct result';

    # string predicate
    is self->run('(string? "foo" 23)'), 1, 'string predicate returns true on strings and numbers';
    is self->run('(string? "foo" #f)'), undef, 'string predicate returns false on undefined value';
    is self->run('(string? "foo" (list 2 3))'), undef, 'string predicate returns false on reference';
    throws_ok { $self->run('(string?)') } 'Script::SXC::Exception', 'string predicate without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/string\?/, 'error message contains "string?"';

    # string equality
    is self->run('(eq? "a" "a")'), 1, 'string equality with two equal elements returns true';
    is self->run('(eq? "a" "a" "a")'), 1, 'string equality with more than two equal elements returns true';
    is self->run('(eq? "a" "a" "b")'), undef, 'string equality with non-equal values returns undefined value';
    throws_ok { $self->run('(eq? "a")') } 'Script::SXC::Exception', 'string equality with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/eq\?/, 'error message contains "eq?"';

    # string non-equality
    is self->run('(ne? "foo" "bar")'), 1, 'string non-equality with two non equal strings returns true';
    is self->run('(ne? "foo" "foo")'), undef, 'string non-equality with two equal strings returns false';
    is self->run('(ne? "foo" "bar" "foo")'), undef, 'string non-equality with some equal strings returns false';
    throws_ok { $self->run('(ne? "a")') } 'Script::SXC::Exception', 'string non-equality with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/ne\?/, 'error message contains "ne?"';

    # less than
    is self->run('(lt? "a" "b")'), 1, 'true less-than with two arguments works';
    is self->run('(lt? "a" "b" "c")'), 1, 'true less-than with more than two arguments works';
    is self->run('(lt? "b" "a")'), undef, 'false less-than with two values works';
    is self->run('(lt? "a" "b" "a")'), undef, 'false less-than with more than two values works';
    is self->run('(lt? "a" "b" "b")'), undef, 'two equal values are wrong in the eyes of less-than';
    throws_ok { $self->run('(lt? "a")') } 'Script::SXC::Exception', 'less-than with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/lt\?/, 'error message contains "lt?"';

    # greater than
    is self->run('(gt? "b" "a")'), 1, 'true greater-than with two arguments works';
    is self->run('(gt? "c" "b" "a")'), 1, 'true greater-than with more than two arguments works';
    is self->run('(gt? "a" "b")'), undef, 'false greater-than with two values works';
    is self->run('(gt? "d" "c" "b" "c")'), undef, 'false greater-than with more than two values works';
    is self->run('(gt? "b" "a" "a")'), undef, 'two equal values are wrong in the eyes of greater-than';
    throws_ok { $self->run('(gt? "a")') } 'Script::SXC::Exception', 'greater-than with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/gt\?/, 'error message contains "gt?"';

    # less than or equal
    is self->run('(le? "a" "b")'), 1, 'true less-than-or-equal with two arguments works';
    is self->run('(le? "a" "b" "c")'), 1, 'true less-than-or-equal with more than two arguments works';
    is self->run('(le? "b" "a")'), undef, 'false less-than-or-equal with two values works';
    is self->run('(le? "a" "b" "a")'), undef, 'false less-than-or-equal with more than two values works';
    is self->run('(le? "a" "b" "b")'), 1, 'two equal values are true in the eyes of less-than-or-equal';
    throws_ok { $self->run('(le? "a")') } 'Script::SXC::Exception', 'less-than-or-equal with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/le\?/, 'error message contains "le?"';

    # greater than or equal
    is self->run('(ge? "b" "a")'), 1, 'true greater-than-or-equal with two arguments works';
    is self->run('(ge? "c" "b" "a")'), 1, 'true greater-than-or-equal with more than two arguments works';
    is self->run('(ge? "a" "b")'), undef, 'false greater-than-or-equal with two values works';
    is self->run('(ge? "d" "c" "b" "c")'), undef, 'false greater-than-or-equal with more than two values works';
    is self->run('(ge? "b" "a" "a")'), 1, 'two equal values are true in the eyes of greater-than-or-equal';
    throws_ok { $self->run('(ge? "a")') } 'Script::SXC::Exception', 'greater-than-or-equal with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/ge\?/, 'error message contains "ge?"';

    # join
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

1;
