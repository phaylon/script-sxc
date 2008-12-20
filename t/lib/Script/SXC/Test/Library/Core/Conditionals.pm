package Script::SXC::Test::Library::Core::Conditionals;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T100_conditionals: Tests {
    my $self = self;

    # if
    is self->run('(if 2 3)'), 3, 'if without alternative and true condition returns consequence';
    is self->run('(if 0 3)'), undef, 'if without alternative and false condition returns undef';
    is self->run('(if 2 3 4)'), 3, 'if with alternative and true condition returns consequence';
    is self->run('(if 0 3 4)'), 4, 'if with alternative and false condition returns alternative';
    is self->run('(if (or #f 3) (and 2 3) 4)'), 3, 'if with true condition returns consequence result';
    throws_ok { $self->run('(if)') } 'Script::SXC::Exception::ParseError', 'if without elements throws parse error';
    throws_ok { $self->run('(if 23)') } 'Script::SXC::Exception::ParseError', 'if with only single element throws parse error';
    throws_ok { $self->run('(if 1 2 3 4)') } 'Script::SXC::Exception::ParseError', 'if with more than three elements throws parse error';
}

1;
