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
    eval { $self->run('apply')->(2, 3) };
    isa_ok $@, 'Script::SXC::Exception::ArgumentError', 'first class apply with wrong arguments throws argument error';
    my $file = __FILE__;
    like $@->source_description, qr/\Q$file\E/, 'source description contains caller package when called from perlspace';
#    exit 7;

    # from inside
    unless ($ENV{TEST_TAILCALLOPT}) {
#        my $caller = self->run("(lambda (f)\n(let [(x 23)\n(y 42)]\n(f list x y)))");
#        my $apply  = self->run('apply');
#        eval { $caller->($apply) };
#        exit 7;
#        local $TODO = 'report correct line number';
        throws_ok { $self->run("((lambda (f)\n(let ((x 23)\n(y 42))\n(f list x y)))\napply)") }
            'Script::SXC::Exception::ArgumentError', 
            'first class apply with wrong arguments throws argument error';
        is $@->source_description, '(scalar)', 'source description indicates scalar evaluation';
        is $@->line_number, 4, 'source line number is correct';
#        exit 7;
    }
}

1;
