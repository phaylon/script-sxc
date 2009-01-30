package Script::SXC::Test::Library::Core::Environments;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T510_environments: Tests {
    my $self = shift;

    # direct builtin access
    {   my $list = $self->run('(let ((list "new-list-symbol")) ((builtin list) list))');
        is_deeply $list, ["new-list-symbol"], 'builtin was accessed and applied successfully';

        throws_ok { $self->run('(builtin)') } 'Script::SXC::Exception::ParseError', 
            'builtin access without arguments throws parse error';
        like $@, qr/missing/i, 'error message contains "missing"';

        throws_ok { $self->run('(builtin list 23)') } 'Script::SXC::Exception::ParseError', 
            'builtin access throws parse error with too many arguments';
        like $@, qr/too many/i, 'error message contains "missing"';

        throws_ok { $self->run('(builtin shouldntexist)') } 'Script::SXC::Exception::UnboundVar', 
            'trying to access an unknown builtin throws an unbound variable error';
        is $@->name, 'shouldntexist', 'error message is about correct symbol';

        throws_ok { $self->run('(builtin :foo)') } 'Script::SXC::Exception::ParseError',
            'builtin access with non symbol argument throws parse error';
        like $@, qr/symbol/i, 'error message contains "symbol"';
    }
}

1;
