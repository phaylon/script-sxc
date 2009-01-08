package Script::SXC::Test::Library::Core::Applications;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );
use DateTime;

sub T100_simple: Tests {
    is_deeply self->run('(apply list (list 1 2 3))'), [1, 2, 3], 'apply with single list argument returns proper result';
    is_deeply self->run('(apply list 1 2 3 (list 4 5))'), [1 .. 5], 'apply with items and list as arguments returns proper result';
}

sub T666_errors: Tests {
    my $self = self;

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
}

sub T200_lists: Tests {
    my $self = self;

    is self->run('(apply (list 2 3 4) (list 1))'), 3, 'list target application returns correct value';
    throws_ok { $self->run('(apply (list 2 3 4) (list 1 2))') } 'Script::SXC::Exception::ArgumentError',
        'list target application with too many arguments throws argument error';
}

sub T300_hashes: Tests {
    my $self = self;

    is self->run('(apply (hash x: 2 y: 3) (list :x))'), 2, 'hash target application returns correct value';
    throws_ok { $self->run('(apply (hash x: 2 y: 3) (list :x :y))') } 'Script::SXC::Exception::ArgumentError',
        'hash target application with too many arguments throws argument error';
}

{   package TestFoo;
    sub new { shift and bless { @_ } }
    sub bar { 23 * $_[1] }
    sub baz { 23 * $_[0]->{ $_[1] } }
}

sub T400_classes: Tests {

    isa_ok self->run('("TestFoo" :new)'), 'TestFoo';
    is self->run('(let ((class "TestFoo")) (bar: class 2))'), 46, 'complex class call example';
}

sub T500_objects: Tests {

    is self->run('((new: "TestFoo") :bar 2)'), 46, 'simple object method call';
    is self->run('(baz: (new: "TestFoo" :qux 2) :qux)'), 46, 'object method call with argument';
    
    {   my $before = DateTime->now(time_zone => 'local')->year;
        my $year   = self->run('((current-datetime) :year)');
        my $after  = DateTime->now(time_zone => 'local')->year;
        ok $year, 'optimised object application returned value';
        ok $before <= $year && $year <= $after, 'returned value is correct';
    }
}
    
sub T700_keyword_swap: Tests {   
    my $return = self->run('(define (r o) o) (foo: r)');
    isa_ok $return, 'Script::SXC::Runtime::Keyword';
    is "$return", 'foo', 'swapped invocant keyword has correct value';
}

1;
