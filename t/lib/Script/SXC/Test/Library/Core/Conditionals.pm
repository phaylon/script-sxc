package Script::SXC::Test::Library::Core::Conditionals;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T100_if: Tests {
    my $self = self;

    is self->run('(if 2 3)'), 3, 'if without alternative and true condition returns consequence';
    is self->run('(if 0 3)'), undef, 'if without alternative and false condition returns undefined value';
    is self->run('(if 2 3 4)'), 3, 'if with alternative and true condition returns consequence';
    is self->run('(if 0 3 4)'), 4, 'if with alternative and false condition returns alternative';
    is self->run('(if (or #f 3) (and 2 3) 4)'), 3, 'if with true condition returns consequence result';
    throws_ok { $self->run('(if)') } 'Script::SXC::Exception::ParseError', 'if without elements throws parse error';
    like $@, qr/if/, 'error message contains "if"';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(if 23)') } 'Script::SXC::Exception::ParseError', 'if with only single element throws parse error';
    like $@, qr/if/, 'error message contains "if"';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(if 1 2 3 4)') } 'Script::SXC::Exception::ParseError', 'if with more than three elements throws parse error';
    like $@, qr/if/, 'error message contains "if"';
    like $@, qr/too many/i, 'error message contains "too many"';
}

sub T200_unless: Tests {
    my $self = self;

    is self->run('(unless 2 3)'), undef, 'unless without alternative and true condition returns undefined value';
    is self->run('(unless 0 3)'), 3, 'unless without alternative and false condition returns consequence';
    is self->run('(unless 2 3 4)'), 4, 'unless with alternative and true condition returns alternative';
    is self->run('(unless 0 3 4)'), 3, 'unless with alternative and false condition returns consequence';
    is self->run('(unless (or #f 3) 4 (and 2 3))'), 3, 'unless with true condition returns alternative result';
    throws_ok { $self->run('(unless)') } 'Script::SXC::Exception::ParseError', 'unless without elements throws parse error';
    like $@, qr/unless/, 'error message contains "unless"';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(unless 23)') } 'Script::SXC::Exception::ParseError', 'unless with only single element throws parse error';
    like $@, qr/unless/, 'error message contains "unless"';
    like $@, qr/missing/i, 'error message contains "missing"';
    throws_ok { $self->run('(unless 1 2 3 4)') } 'Script::SXC::Exception::ParseError', 'unless with more than three elements throws parse error';
    like $@, qr/unless/, 'error message contains "unless"';
    like $@, qr/too many/i, 'error message contains "too many"';
}

1;
