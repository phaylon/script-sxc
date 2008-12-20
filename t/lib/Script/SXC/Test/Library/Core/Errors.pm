package Script::SXC::Test::Library::Core::Errors;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T950_errors: Tests {
    my $self  = self;
    my $class = ref $self;

    # from here
    throws_ok { $self->run('apply')->(2, 3) } 'Script::SXC::Exception::ArgumentError', 
        'first class apply with wrong arguments throws argument error';
    like $@->source_description, qr/$class/, 'source description contains caller package when called from perlspace';

    # from inside
    unless ($ENV{TEST_TAILCALLOPT}) {
        my $caller = self->run("(lambda (f)\n(let [(x 23)\n(y 42)]\n(f list x y)))");
        my $apply  = self->run('apply');
        throws_ok { $caller->($apply) } 'Script::SXC::Exception::ArgumentError',
            'first class apply with wrong arguments throws argument error';
        is $@->source_description, '(scalar)', 'source description indicates scalar evaluation';
        is $@->line_number, 4, 'source line number is correct';
    }
}

1;
