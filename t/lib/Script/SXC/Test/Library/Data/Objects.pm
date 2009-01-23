package Script::SXC::Test::Library::Data::Objects;
use strict;
use parent 'Script::SXC::Test::Library::Data';
use CLASS;
use Test::Most;
use self;

require DateTime;

sub T100_predicate: Tests {
    my $self = self;

    is self->run('(object? (current-datetime))'), 1, 'object predicate returns 1 on object';
    is self->run('(object? (current-datetime) (current-datetime))'), 1, 'object predicate returns 1 on multiple objects';
    is self->run('(object? 23)'), undef, 'object predicate returns undefined value on non-object';
    is self->run('(object? (current-datetime) 23)'), undef, 'object predicate returns undefined value on object and non-object';

    throws_ok { $self->run('(object?)') } 'Script::SXC::Exception', 'object predicate throws exception when called without arguments';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/object\?/, 'error message contains "object?"';

    is self->run('(object? :foo)'), undef, 'object predicate returns undefined value on keyword';
    is self->run('(object? (quote foo))'), undef, 'object predicate returns undefined value on symbol';
}

sub T110_isa_predicate: Tests {
    my $self = self;

    is self->run('(isa? (current-datetime) "DateTime")'), 1, 'isa? returns 1 when true on object';
    is self->run('(isa? (current-datetime) "FHTAGN!")'), undef, 'isa? returns undefined value when false on object';
    is self->run('(isa? "DateTime" "UNIVERSAL")'), 1, 'isa? returns 1 when true on class';
    is self->run('(isa? "DateTime" "FNORD!")'), undef, 'isa? returns undefined value when false on class';
    is self->run('(isa? { foo: 23 } "Foo")'), undef, 'isa? returns undefined value on invalid invocant';

    throws_ok { $self->run('(isa? "DateTime")') } 'Script::SXC::Exception', 
        'isa? throws exception when called with one argument';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/isa\?/, 'error message contains "isa?"';

    throws_ok { $self->run('(isa? "DateTime" "UNIVERSAL" "FNORD")') } 'Script::SXC::Exception',
        'isa? throws exception when called with three arguments';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/isa\?/, 'error message contains "isa?"';

    is self->run('(isa? :foo "Script::SXC::Runtime::Object")'), undef, 'isa? does not treat keywords as objects';
    is self->run('(isa? `foo "Script::SXC::Runtime::Object")'), undef, 'isa? does not treat symbols as objects';
}

sub T120_can_predicate: Tests {
    my $self = self;

    is self->run('(can? (current-datetime) :year)'), 1, 'can? returns 1 when true on object';
    is self->run('(can? (current-datetime) "FHTAGN!")'), undef, 'can? returns undefined value when false on object';
    is self->run('(can? (current-datetime) :year :day)'), 1, 'can? returns 1 when true with multiple methods';
    is self->run('(can? (current-datetime) :year "PAZUZU!")'), undef, 'can? returns undefined value when false with multiple methods';
    is self->run('(can? "DateTime" :year)'), 1, 'can? returns 1 when true on class';
    is self->run('(can? "DateTime" "FNORD!")'), undef, 'can? returns undefined value when false on class';
    is self->run('(can? "DateTime" :year :day)'), 1, 'can? returns 1 when true with multiple class methods';
    is self->run('(can? "DateTime" :year "PAZUZU!")'), undef, 'can? returns undefined value when false with multiple class methods';
    is self->run('(can? { foo: 23 } :whatever)'), undef, 'can? returns undefined value on invalid invocant';

    throws_ok { $self->run('(can? "DateTime")') } 'Script::SXC::Exception', 
        'can? throws exception when called with one argument';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/can\?/, 'error message contains "can?"';

    is self->run('(can? :foo :can)'), undef, 'can? does not treat keywords as objects';
    is self->run('(can? `foo :can)'), undef, 'can? does not treat symbols as objects';
}

my ($FooClass, $FooRoleA, $FooRoleB);
{   
    package Script::SXC::Test::FooRoleA;
    use Moose::Role;
    BEGIN { $INC{'Script/SXC/Test/FooRoleA.pm'} = 'inline test A' }
    $FooRoleA = __PACKAGE__;

    package Script::SXC::Test::FooRoleB;
    use Moose::Role;
    BEGIN { $INC{'Script/SXC/Test/FooRoleB.pm'} = 'inline test B' }
    $FooRoleB = __PACKAGE__;

    package Script::SXC::Test::Foo;
    use Moose;
    with 'Script::SXC::Test::FooRoleA';
    with 'Script::SXC::Test::FooRoleB';
    $FooClass = __PACKAGE__;
}

{
    package Script::SXC::Test::TestRole;
    use Moose::Role;

    package Script::SXC::Runtime::Object;
    use Moose;
    with 'Script::SXC::Test::TestRole';
}

sub T120_does_predicate: Tests {
    my $self = self;

    is self->run(qq{(does? (new: "$FooClass") "$FooRoleA")}), 1, 'does? returns 1 when true on object';
    is self->run(qq{(does? (new: "$FooClass") "FHTAGN!")}), undef, 'does? returns undefined value when false on object';
    is self->run(qq{(does? (new: "$FooClass") "$FooRoleA" "$FooRoleB")}), 1, 'does? returns 1 when true with multiple roles';
    is self->run(qq{(does? (new: "$FooClass") "$FooRoleA" "PAZUZU!")}), undef, 'does? returns undefined value when false with multiple roles';
    is self->run(qq{(does? "$FooClass" "$FooRoleA")}), 1, 'does? returns 1 when true on class';
    is self->run(qq{(does? "$FooClass" "FNORD!")}), undef, 'does? returns undefined value when false on class';
    is self->run(qq{(does? "$FooClass" "$FooRoleA" "$FooRoleB")}), 1, 'does? on class returns 1 when true with multiple roles';
    is self->run(qq{(does? "$FooClass" "$FooRoleA" "PAZUZU!")}), undef, 'does? on class returns undefined value when false with multiple roles';
    is self->run('(does? { foo: 23 } :whatever)'), undef, 'does? returns undefined value on invalid invocant';

    throws_ok { $self->run('(does? "DateTime")') } 'Script::SXC::Exception',
        'can? throws exception when called with one argument';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/does\?/, 'error message contains "does?"';

    is self->run('(does? :foo "Script::SXC::Test::TestRole")'), undef, 'isa? does not treat keywords as objects';
    is self->run('(does? `foo "Script::SXC::Test::TestRole")'), undef, 'isa? does not treat symbols as objects';
}

1;
