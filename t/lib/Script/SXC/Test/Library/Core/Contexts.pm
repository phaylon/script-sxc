package Script::SXC::Test::Library::Core::Contexts;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T800_contexts: Tests {
    my $self = self;

    # list apply
    {   is ref(my $lambda = self->run('(lambda (p) (values->list (p 23)))')), 'CODE', 'values->list compiles';
        is_deeply $lambda->(sub { my $x = shift; return $x, $x * 2, $x * 3 }), [23, 46, 69], 
            'values->list returns list of correct values';
    }

    # hash apply
    {   is ref(my $lambda = self->run('(lambda (p) (values->hash (p 23)))')), 'CODE', 'values->hash parses';
        is_deeply $lambda->(sub { my $x = shift; return foo => $x, bar => $x * 2 }), { foo => 23, bar => 46 }, 
            'values->hash returns hash with correct pairs';
    }

    # exceptions
    for my $context ('values->list', 'values->hash') {

        throws_ok { $self->run("($context 23)") } 'Script::SXC::Exception::ParseError',
            q{trying to use $context on non application throws parse error};
        like $@, qr/invalid/i, 'error message contains "invalid"';
        like $@, qr/\Q$context\E/, q{error message contains "$context"};
        like $@, qr/application/i, 'error message contains "application"';
    }
}

1;
