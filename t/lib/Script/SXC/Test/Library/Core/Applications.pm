package Script::SXC::Test::Library::Core::Applications;
use strict;
use parent 'Script::SXC::Test::Library::Core';
#use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );
use DateTime;

sub T100_simple: Tests {
    my ($self) = @_;
    is_deeply $self->run('(apply list (list 1 2 3))'), [1, 2, 3], 'apply with single list argument returns proper result';
    is_deeply $self->run('(apply list 1 2 3 (list 4 5))'), [1 .. 5], 'apply with items and list as arguments returns proper result';
}

my $SP_Test;
{   
    package Script::SXC::Test::SourcePosition;
    sub new    { bless +{} }
    sub report { [ (caller)[1, 2] ] }
    $SP_Test = __PACKAGE__;
}

sub T050_source_positions: Tests {
    my ($self) = @_;
    return $self->builder->skip("doesn't make sense to test error reporting with active tailcall optimisations")
        if $ENV{TEST_TAILCALLOPT};

    my $apply = $self->run('(λ (f) (f))');

    is_deeply $apply->($SP_Test->can('report')), ['(scalar)', 1], 'code application sets correct line number';

}

sub T666_errors: Tests {
    my ($self) = @_;
#    my $self = self;

    throws_ok { $self->run('(apply)') } 'Script::SXC::Exception',
        'apply without any arguments throws argument error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(apply (λ (n) n))') } 'Script::SXC::Exception',
        'apply with only one argument throws argument error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(apply list 2 3)') } 'Script::SXC::Exception',
        'apply with non list as last argument throws argument error';
    like $@, qr/last/i, 'error message contains "last"';
    like $@, qr/list/i, 'error message contains "list"';

    throws_ok { $self->run('(foo: :foo)') } 'Script::SXC::Exception', 'keyword application throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';

    throws_ok { $self->run('(((λ () :foo)) :foo)') } 'Script::SXC::Exception', 'runtime keyword application throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';

    throws_ok { $self->run("('foo :x)") } 'Script::SXC::Exception', 'symbol application throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';

    throws_ok { $self->run("(((λ () 'foo)) :x)") } 'Script::SXC::Exception', 'runtime symbol application throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';
}

sub T200_lists: Tests {
    my ($self) = @_;
#    my $self = self;

    is $self->run('(apply (list 2 3 4) (list 1))'), 3, 'list target application returns correct value';

    throws_ok { $self->run('(apply (list 2 3 4) (list 1 2))') } 'Script::SXC::Exception::ArgumentError',
        'list target application with too many arguments throws argument error';
    like $@, qr/list/, 'error message contains "list"';
    like $@, qr/single argument/i, 'error message contains "single argument"';

    throws_ok { $self->run('(apply (list 2 3) ())') } 'Script::SXC::Exception::ArgumentError',
        'list target application with missing argument throws argument error';
    like $@, qr/list/, 'error message contains "list"';
    like $@, qr/single argument/i, 'error message contains "single argument"';

    is $self->run('((list 2 3 4) 1)'), 3, 'runtime list application returns correct value';

    throws_ok { $self->run('((list 2 3 4) 1 2)') } 'Script::SXC::Exception::ArgumentError',
        'runtime list application with too many arguments throws argument error';
    like $@, qr/list/, 'error message contains "list"';
    like $@, qr/single argument/i, 'error message contains "single argument"';

    throws_ok { $self->run('((list 2 3))') } 'Script::SXC::Exception::ArgumentError',
        'runtime list application with missing argument throws argument error';
    like $@, qr/list/, 'error message contains "list"';
    like $@, qr/single argument/i, 'error message contains "single argument"';
}

sub T300_hashes: Tests {
    my ($self) = @_;
#    my $self = self;

    is $self->run('(apply (hash x: 2 y: 3) (list :x))'), 2, 'hash target application returns correct value';

    throws_ok { $self->run('(apply (hash x: 2 y: 3) (list :x :y))') } 'Script::SXC::Exception::ArgumentError',
        'hash target application with too many arguments throws argument error';
    like $@, qr/hash/, 'error message contains "hash"';
    like $@, qr/single argument/i, 'error message contains "single argument"';

    throws_ok { $self->run('(apply (hash x: 2 y: 3) ())') } 'Script::SXC::Exception::ArgumentError',
        'hash target application with no arguments throws argument error';
    like $@, qr/hash/, 'error message contains "hash"';
    like $@, qr/single argument/i, 'error message contains "single argument"';

    is $self->run('((hash x: 2 y: 3) :x)'), 2, 'runtime hash application returns correct value';

    throws_ok { $self->run('((hash x: 2 y: 3) :x :y)') } 'Script::SXC::Exception::ArgumentError',
        'runtime hash application with too many arguments throws argument error';
    like $@, qr/hash/, 'error message contains "hash"';
    like $@, qr/single argument/i, 'error message contains "single argument"';

    throws_ok { $self->run('((hash x: 2 y: 3))') } 'Script::SXC::Exception::ArgumentError',
        'runtime hash application with no arguments throws argument error';
    like $@, qr/hash/, 'error message contains "hash"';
    like $@, qr/single argument/i, 'error message contains "single argument"';
}

{   package TestFoo;
    sub new { shift and bless { @_ } }
    sub bar { 23 * $_[1] }
    sub baz { 23 * $_[0]->{ $_[1] } }
}

sub T400_classes: Tests {
    my ($self) = @_;
#    my $self = self;

    # explicit apply
    isa_ok $self->run('(apply "TestFoo" :new ())'), 'TestFoo';
    is $self->run('(let ((class "TestFoo")) (apply bar: class 2 ()))'), 46, 'explicit apply: complex class call example';

    throws_ok { $self->run('(apply "TestFoo" :doesntexist ())') } 'Script::SXC::Exception',
        'explicit apply: trying to call non existing method throws exception';
    is $@->type, 'missing_method', 'exception has type "missing_method"';
    like $@, qr/TestFoo/, 'error message contains class name';
    like $@, qr/doesntexist/, 'error message contains method name';

    throws_ok { $self->run('(apply ((λ () "TestFoo")) :doesntexist ())') } 'Script::SXC::Exception',
        'explicit apply: trying to call non existing method by runtime name throws exception';
    is $@->type, 'missing_method', 'exception has type "missing_method"';
    like $@, qr/TestFoo/, 'error message contains class name';
    like $@, qr/doesntexist/, 'error message contains method name';

    throws_ok { $self->run('(apply "23" :foo ())') } 'Script::SXC::Exception',
        'explicit apply: using a number as invocant throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';

    throws_ok { $self->run('(apply ((λ () "23")) :foo ())') } 'Script::SXC::Exception',
        'explicit apply: using a runtime number as invocant throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';

    # implicit apply
    isa_ok $self->run('("TestFoo" :new)'), 'TestFoo';
    is $self->run('(let ((class "TestFoo")) (bar: class 2))'), 46, 'complex class call example';

    throws_ok { $self->run('("TestFoo" :doesntexist)') } 'Script::SXC::Exception',
        'trying to call non existing method throws exception';
    is $@->type, 'missing_method', 'exception has type "missing_method"';
    like $@, qr/TestFoo/, 'error message contains class name';
    like $@, qr/doesntexist/, 'error message contains method name';

    throws_ok { $self->run('(((λ () "TestFoo")) :doesntexist)') } 'Script::SXC::Exception',
        'trying to call non existing method by runtime name throws exception';
    is $@->type, 'missing_method', 'exception has type "missing_method"';
    like $@, qr/TestFoo/, 'error message contains class name';
    like $@, qr/doesntexist/, 'error message contains method name';

    throws_ok { $self->run('("23" :foo)') } 'Script::SXC::Exception',
        'using a number as invocant throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';

    throws_ok { $self->run('(((λ () "23")) :foo)') } 'Script::SXC::Exception',
        'using a runtime number as invocant throws exception';
    is $@->type, 'invalid_invocant_type', 'exception has correct type';
}

sub T500_objects: Tests {
    my ($self) = @_;
#    my $self = self;

    # implicit apply
    is $self->run('((new: "TestFoo") :bar 2)'), 46, 'simple object method call';
    is $self->run('(baz: (new: "TestFoo" :qux 2) :qux)'), 46, 'object method call with argument';
    
    {   my $before = DateTime->now(time_zone => 'local')->year;
        my $year   = $self->run('((current-datetime) :year)');
        my $after  = DateTime->now(time_zone => 'local')->year;
        ok $year, 'optimised object application returned value';
        ok $before <= $year && $year <= $after, 'returned value is correct';
    }

    throws_ok { $self->run('((new: "TestFoo") :doesntexist)') } 'Script::SXC::Exception',
        'trying to call non existing method on object throws exception';
    is $@->type, 'missing_method', 'exception has type "missing_method"';
    like $@, qr/TestFoo/, 'error message contains class name';
    like $@, qr/doesntexist/, 'error message contains method name';

    # explicit apply
    is $self->run('(apply (new: "TestFoo") :bar 2 ())'), 46, 'explicit apply: simple object method call';
    is $self->run('(apply baz: (new: "TestFoo" :qux 2) :qux ())'), 46, 'explicit apply: object method call with argument';
    
    {   my $before = DateTime->now(time_zone => 'local')->year;
        my $year   = $self->run('(apply (current-datetime) :year ())');
        my $after  = DateTime->now(time_zone => 'local')->year;
        ok $year, 'explicit apply: optimised object application returned value';
        ok $before <= $year && $year <= $after, 'returned value is correct';
    }

    throws_ok { $self->run('(apply (new: "TestFoo") :doesntexist ())') } 'Script::SXC::Exception',
        'explicit apply: trying to call non existing method on object throws exception';
    is $@->type, 'missing_method', 'exception has type "missing_method"';
    like $@, qr/TestFoo/, 'error message contains class name';
    like $@, qr/doesntexist/, 'error message contains method name';
}
    
sub T700_keyword_swap: Tests {  
    my ($self) = @_;

    my $return = $self->run('(define (r o) o) (foo: r)');
    isa_ok $return, 'Script::SXC::Runtime::Keyword';
    is "$return", 'foo', 'swapped invocant keyword has correct value';

    isa_ok $self->run('(define (r o) o) (apply foo: r ())'), 'Script::SXC::Runtime::Keyword';
}

sub T800_set_application: Tests {
    my ($self) = @_;

    is_deeply $self->run('(define n 23) (apply! n ++) (apply! n list) (apply! (list-ref n 0) ++) n'),
        [25],
        'set application works';

    throws_ok { $self->run('(define foo 23) (apply! foo)') } 'Script::SXC::Exception',
        'apply! without applicant throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(define foo 23) (apply! foo ++ 8)') } 'Script::SXC::Exception',
        'apply! with too many arguments throws exception';
    like $@, qr/too many/i, 'error message contains "too many"';

    throws_ok { $self->run('(apply! foo ++)') } 'Script::SXC::Exception::UnboundVar',
        'apply! throws unbound variable exception when called on non-existing variable';
    like $@, qr/foo/, 'error message contains variable name';
}

1;
