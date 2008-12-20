package Script::SXC::Test::Library::Core::Applications;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T850_applications: Tests {
    my $self = self;

    # simple application
    is_deeply self->run('(apply list (list 1 2 3))'), [1, 2, 3], 'apply with single list argument returns proper result';
    is_deeply self->run('(apply list 1 2 3 (list 4 5))'), [1 .. 5], 'apply with items and list as arguments returns proper result';

    # errors
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

    # list application
    is self->run('(apply (list 2 3 4) (list 1))'), 3, 'list target application returns correct value';
    throws_ok { $self->run('(apply (list 2 3 4) (list 1 2))') } 'Script::SXC::Exception::ArgumentError',
        'list target application with too many arguments throws argument error';

    # hash application
    is self->run('(apply (hash x: 2 y: 3) (list :x))'), 2, 'hash target application returns correct value';
    throws_ok { $self->run('(apply (hash x: 2 y: 3) (list :x :y))') } 'Script::SXC::Exception::ArgumentError',
        'hash target application with too many arguments throws argument error';

    # keyword invocant swap
    {   my $return = self->run('(define (r o) o) (foo: r)');
        isa_ok $return, 'Script::SXC::Runtime::Keyword';
        is "$return", 'foo', 'swapped invocant keyword has correct value';
    }
}

1;
