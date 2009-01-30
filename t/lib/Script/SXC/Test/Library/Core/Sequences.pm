package Script::SXC::Test::Library::Core::Sequences;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub callstack_count {
    my $i = 0;
    $i++ until caller($i) eq 'main';
    return $i;
}

sub T050_sequences: Tests {
    my $self = shift;

    # begin
    is $self->run('(begin 5 4 3 2)'), 2, 'begin sequence returns last value';
    {   is ref(my $lambda = $self->run('(define foo (lambda (t) (begin (define r (t)) (if r (foo t) ()))))')), 
            'CODE', 
            'begin sequence with tailcall compiles';
        my $old;
        my $x = 0;
        is_deeply $lambda->(sub {
            my $new = callstack_count;
            if (defined($old) and $ENV{TEST_TAILCALLOPT}) {
                is $new, $old, "begin sequence with tailcall on iteration $x still has callstack count of $old";
            }
            elsif (defined $old) {
                ok $new > $old, "begin sequence with tailcall on iteration $x increased callstack count ($old -> $new)";
            }
            $old = $new;
            return not $x++ == 5;
        }), [], 'begin sequence with tailcall';
    }
    throws_ok { $self->run('(begin)') } 'Script::SXC::Exception::ParseError', 'begin without body throws parse error';
}

1;
