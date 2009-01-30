package Script::SXC::Test::Library::Core::DateTime;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T100_sleep: Tests {
    my $self = shift;

    is ref(my $sleeper = $self->run('(λ (s) (sleep s))')), 'CODE', 'sleeper function compiles';

    {   my $start = time;
        $sleeper->(3);
        ok time > $start + 2, 'sleeper has slept at least 2 seconds';
    }

    {   my $start = time;
        $sleeper->(0.5);
        ok time < $start + 1.5, 'sleeper has slept no more than 1.5 seconds';
    }

    throws_ok { $self->run('(sleep)') } 'Script::SXC::Exception', 'sleep without arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/sleep/, 'error message contains "sleep"';

    throws_ok { $self->run('(sleep 3 4)') } 'Script::SXC::Exception', 'sleep with two arguments throws exception';
    like $@, qr/too\s+many/i, 'error message contains "too many"';
    like $@, qr/sleep/, 'error message contains "sleep"';
}

sub T200_current_timestamp: Tests {
    my $self = shift;

    {   my $before    = time;
        my $timestamp = $self->run('(current-timestamp)');
        ok $before <= $timestamp, 'current-timestamp return value is big enough';
        ok $timestamp <= time, 'current-timestamp return value is small enough';
    }

    throws_ok { $self->run('(current-timestamp 17)') } 'Script::SXC::Exception', 'current-timestamp throws exception with arguments';
    like $@, qr/too\s+many/i, 'error message contains "too many"';
    like $@, qr/current-timestamp/, 'error message contains "current-timestamp"';
}

sub T300_current_datetime: Tests {
    my $self = shift;

    {   my $before   = time;
        my $datetime = $self->run('(current-datetime)');
        isa_ok $datetime, 'DateTime';
        ok $before <= $datetime->epoch, 'datetime object epoch is big enough';
        ok $datetime->epoch <= time, 'datetime object epoch is small enough';
    }

    throws_ok { $self->run('(current-datetime 17)') } 'Script::SXC::Exception', 'current-datetime throws exception with arguments';
    like $@, qr/too\s+many/i, 'error message contains "too many"';
    like $@, qr/current-datetime/, 'error message contains "current-datetime"';
}

sub T800_sync: Tests {
    my $self = shift;

    {   my $datetime  = $self->run('(epoch: (current-datetime))');
        my $timestamp = $self->run('(current-timestamp)');
        my ($min, $max) = sort $datetime, $timestamp;
        ok $max - $min < 5, 'current-datetime and current-timestamp are close enough';
    }
}

1;
