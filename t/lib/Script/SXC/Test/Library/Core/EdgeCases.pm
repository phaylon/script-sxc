package Script::SXC::Test::Library::Core::EdgeCases;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T900_edge_cases: Tests {
    my $self = shift;

    # typehinting does not break execution after set
    # FIXME needs different implemented applications to be tested
    {   my $code = q{
            (define (foo x) x)
            (define (bar y) (foo y))    ; this should not be hardhinted
            (set! foo #f)
            (bar 23)
        };
        throws_ok { $self->run($code) } 'Script::SXC::Exception::TypeError',
            'change of invocant var after lambda definition throws correct type error';
        like $@, qr/invocant/i, 'error message contains "invocant"';
    }

    # shadowing builtin
    is $self->run('(let ((list 23)) list)'), 23, 'builtin variables can be shadowed';

    # runtime application of inline procedure works
    is_deeply $self->run('(apply hash (list x: 23 y: 47))'), { x => 23, y => 47 }, 
        'runtime application of inline procedure has runtime argument check';
}

1;
