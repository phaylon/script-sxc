package Script::SXC::Test::Library::Core::Recursions;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T525_recursions: Tests {
    my $self = self;

    my $build_counter = sub {
        my $name = shift;
        my $left  = my $start = shift(@_) || 5;
        my $count = 1;
        return sub {
            BAIL_OUT("$name: too many calls ($count)")
                if $count >= ($start + 10);
            ok 1, "$name: call number " . ( $count++ );
            return --$left;
        };
    };

    # simple recursion
    {   is ref(my $rec = self->run('(λ (t) (recurse foo ((ls (list 777))) (let ((r (t))) (if r (foo (list r ls)) ls))))')), 'CODE',
            'recurse with simple call compiles';
        is_deeply $rec->($build_counter->('simple recurse')), [1, [2, [3, [4, [777]]]]], 'simple recurse has correct values';
    }
}

1;
