package Script::SXC::Test::Library::Data::Regex;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use Data::Dump   qw( dump );
use Scalar::Util qw( refaddr );

sub T200_match: Tests {
    my $self = shift;

    is_deeply $self->run('(match /(f)(o)(o)/ "foo")'), [qw( f o o )], 'match with captures returns list of captures';
    is_deeply $self->run('(match /foo/ "foo")'), [1], 'match without captures returns list containing true';
    is_deeply $self->run('(match /foo/ "foofoo")'), [1], 'match with multiple possible matches does not act global';
    is $self->run('(match /foo/ "bar")'), undef, 'match on non-matching string returns undefined value';
    
    throws_ok { $self->run('(match /foo/)') } 'Script::SXC::Exception', 'match with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/match/, 'error message contains "match"';

    throws_ok { $self->run('(match /foo/ "foo" 23)') } 'Script::SXC::Exception', 'match with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/match/, 'error message contains "match"';

    throws_ok { $self->run('(match 23 "foo")') } 'Script::SXC::Exception', 'match with non regex as first argument throws exception';
    like $@, qr/regex|regular expression/i, 'error message contains "regex"';
    like $@, qr/match/, 'error message contains "match"';
}

sub T300_match_all: Tests {
    my $self = shift;

    is_deeply $self->run('(match-all /(f)(o)(o)/ "foofoo")'), [qw( f o o f o o )], 'match-all with captures returns list of captures';
    is_deeply $self->run('(match-all /foo/ "foo")'), ['foo'], 'match-all without captures and one match returns list with full match';
    is_deeply $self->run('(match-all /foo/ "foofoo")'), ['foo', 'foo'], 'match-all with multiple possible matches returns list with full matches';
    is $self->run('(match-all /foo/ "bar")'), undef, 'match-all on non-matching string returns undefined value';
    
    throws_ok { $self->run('(match-all /foo/)') } 'Script::SXC::Exception', 'match-all with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/match-all/, 'error message contains "match-all"';

    throws_ok { $self->run('(match-all /foo/ "foo" 23)') } 'Script::SXC::Exception', 'match-all with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/match-all/, 'error message contains "match-all"';

    throws_ok { $self->run('(match-all 23 "foo")') } 'Script::SXC::Exception', 'match-all with non regex as first argument throws exception';
    like $@, qr/regex|regular expression/i, 'error message contains "regex"';
    like $@, qr/match-all/, 'error message contains "match-all"';
}

sub T400_named_match: Tests {
    my $self = shift;

    is_deeply $self->run('(named-match /(?<Foo>23)(?<Bar>42)/ "2342")'), { Foo => 23, Bar => 42 },
        'named-match returns correct structure';
    is_deeply $self->run('(named-match /(?<A>foo)(?<A>bar)/ "foobar")'), { A => 'foo' },
        'named-match with multiple matches per name returns first match in structure';
    is $self->run('(named-match /(?<A>foo)/ "bar")'), undef, 'named-match without match returns undefined value';
    
    throws_ok { $self->run('(named-match /foo/)') } 'Script::SXC::Exception', 'named-match with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/named-match/, 'error message contains "named-match"';

    throws_ok { $self->run('(named-match /foo/ "foo" 23)') } 'Script::SXC::Exception', 'named-match with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/named-match/, 'error message contains "named-match"';

    throws_ok { $self->run('(named-match 23 "foo")') } 'Script::SXC::Exception', 'named-match with non regex as first argument throws exception';
    like $@, qr/regex|regular expression/i, 'error message contains "regex"';
    like $@, qr/named-match/, 'error message contains "named-match"';
}

sub T400_named_match_full: Tests {
    my $self = shift;

    is_deeply $self->run('(named-match-full /(?<Foo>23)(?<Bar>42)/ "2342")'), { Foo => [23], Bar => [42] },
        'named-match-full returns correct structure';
    is_deeply $self->run('(named-match-full /(?<A>foo)(?<A>bar)/ "foobar")'), { A => ['foo', 'bar'] },
        'named-match-full with multiple matches per name returns all matches in structure';
    is $self->run('(named-match-full /(?<A>foo)/ "bar")'), undef, 'named-match-full without match returns undefined value';
    
    throws_ok { $self->run('(named-match-full /foo/)') } 'Script::SXC::Exception', 'named-match-full with single argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/named-match-full/, 'error message contains "named-match-full"';

    throws_ok { $self->run('(named-match-full /foo/ "foo" 23)') } 'Script::SXC::Exception', 
        'named-match-full with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/named-match-full/, 'error message contains "named-match-full"';

    throws_ok { $self->run('(named-match-full 23 "foo")') } 'Script::SXC::Exception', 
        'named-match-full with non regex as first argument throws exception';
    like $@, qr/regex|regular expression/i, 'error message contains "regex"';
    like $@, qr/named-match-full/, 'error message contains "named-match-full"';
}

1;
