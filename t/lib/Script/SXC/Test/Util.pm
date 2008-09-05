package Script::SXC::Test::Util;
use strict;

use Test::Most;
use Carp qw( croak );

use Sub::Exporter -setup => {
    exports => [qw(
        assert_ok
        list_ok
        symbol_ok
        builtin_ok
        quote_ok
    )],
};

sub assert_ok {
    my ($msg, $val, @rest) = @_;
    local $Test::Builder::Level = 2;
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok $val, $msg;
    return wantarray ? ($val, @rest) : $val;
}

sub list_ok {
    my ($ls, $name, %other) = @_;
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $list_class = $other{list_class} || 'Script::SXC::Tree::List';
    local $Test::Builder::Level = 2;
    isa_ok $ls, $list_class;

    if (my $count = $other{content_count}) {
        is $ls->content_count, $count, "$name has the correct content count";
    }

    if (my $test = $other{content_test}) {
        #local $Test::Builder::Level = $Test::Builder::Level + 1;
#        local $Test::Builder::Level = 2;
        for my $x (0 .. $#$test) {
            my $t = $test->[ $x ];
            local $_ = $ls->get_content_item($x);
            $t->($ls, $_, $x);
        }
    }

    return $ls;
}

sub tree_ok {
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Test::Builder::Level = 2;
    list_ok @_, list_class => 'Script::SXC::Tree';
}

sub symbol_ok {
    my ($sym, $name, %other) = @_;
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Test::Builder::Level = 2;
    isa_ok $sym, 'Script::SXC::Tree::Symbol';

    use Data::Dump qw( dump );

    if (my $value = $other{value}) {
        is $value, $sym->value, "$name has correct value";
    }

    return $sym;
}

sub builtin_ok {
    my ($bi, $name, %other) = @_;
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Test::Builder::Level = 2;
    isa_ok $bi, 'Script::SXC::Tree::Builtin';

    return symbol_ok @_;
}

sub quote_ok {
    my ($quo, $name, %other) = @_;
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Test::Builder::Level = 2;

    my $quote_name = $other{quote_name}
        or croak "Missing quotename for test";
    my $quote_test = $other{quote_test};

    list_ok $quo, "$name list",
        content_count => 2,
        content_test  => [
            sub { builtin_ok $_, "$quote_name builtin", value => $quote_name },
            $quote_test || (),
        ];
}

1;
