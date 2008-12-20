package Script::SXC::Test::Library::Core::Operators;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T010_operators: Tests {

    # or
    is self->run('(or 1 2)'), 1, 'or with two true values returns first true value';
    is self->run('(or #f 17)'), 17, 'or with a false and a true value returns first true value';
    is self->run('(or #f 0)'), 0, 'or with no true value is false';
    is self->run('(or 23)'), 23, 'or with one true value returns value';
    is self->run('(or 0)'), 0, 'or with one false value returns value';
    is self->run('(or)'), undef, 'or without value returns undef';

    # and
    is self->run('(and 1 2 3)'), 3, 'and with three true values returns last true value';
    is self->run('(and 1 2 0)'), 0, 'and with true and false values returns first false value';
    is self->run('(and 0 #f)'), 0, 'and with no true values returns first false value';
    is self->run('(and 23)'), 23, 'and with one true value returns value';
    is self->run('(and 0)'), 0, 'and with one false value returns value';
    is self->run('(and)'), undef, 'and without value returns undef';

    # not
    ok !self->run('(not 2)'), 'not with true value is false';
    ok self->run('(not 0)'), 'not with false value is true';
    ok self->run('(not #f 0)'), 'not with only false values is true';
    ok !self->run('(not #f 2 0)'), 'not with true value in between is false';
    ok !self->run('(not 1 2 3)'), 'not with only true values is false';
    is self->run('(not)'), undef, 'not without values is undef';

    # err
    is self->run('(err 2 3)'), 2, 'err with two defined values returns first value';
    is self->run('(err #f 23)'), 23, 'err with undefined and defined value returns defined value';
    is self->run('(err #f #f)'), undef, 'err with undefined values returns undefined';
    is self->run('(err)'), undef, 'err with no arguments returns undefined';
    is self->run('(err #f 0 23)'), 0, 'err with false value returns false value';

    # def
    ok self->run('(def 23)'), 'def with defined value returns true';
    ok self->run('(def 0)'), 'def with false but defined value returns true';
    ok !self->run('(def #f)'), 'def with undefined value returns false';
    ok self->run('(def 2 3 4)'), 'def with multiple defined arguments returns true';
    ok self->run('(def 2 0 9)'), 'def with multiple defined but false arguments returns true';
    ok !self->run('(def 2 3 #f 4)'), 'def with multiple but one undefined value returns false';
    ok !self->run('(def #f #f #f)'), 'def with multiple undefined values returns false';
}

1;
