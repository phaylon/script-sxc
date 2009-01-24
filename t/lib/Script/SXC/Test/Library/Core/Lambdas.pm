package Script::SXC::Test::Library::Core::Lambdas;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T100_simplest: Tests {

    my $lambda = self->run('(lambda () 23)');
    is ref($lambda), 'CODE', 'simple lambda returned code reference';
    is $lambda->(), 23, 'execution of lambda returned evaluated body expression';
}

sub T110_simple_with_list: Tests {

    my $lambda = self->run('(lambda foo 23)');
    is ref($lambda), 'CODE', 'lambda with list parameter returned code reference';
    is $lambda->(), 23, 'execution of lambda returned evaluated body expression';
}

sub T120_simple_with_single_param: Tests {   

    my $lambda = self->run('(lambda (n) 23)');
    is ref($lambda), 'CODE', 'lambda with one parameter returned code reference';
    is $lambda->(42), 23, 'execution of lambda returned evaluated body expression';
}

sub T130_simple_with_single_and_access: Tests {

    my $lambda = self->run('(lambda (n) n)');
    is ref($lambda), 'CODE', 'lambda with one parameter returned code reference';
    is $lambda->(777), 777, 'lambda with one parameter and local environment access returns passed value';
}

sub T150_kons_and_kar: Tests {   

    my $kons = self->run('(lambda (n m) (lambda (f) (f n m)))');
    is ref($kons), 'CODE', 'kons lambda definition returned code reference';

    my $kar = self->run('(lambda (p) (p (lambda (n m) n)))');
    is ref($kar), 'CODE', 'kar lambda definition returned code reference';

    my $kdr = self->run('(lambda (p) (p (lambda (n m) m)))');
    is ref($kdr), 'CODE', 'kdr lambda definition returned code reference';

    my $pair = $kons->(23, 42);
    is ref($pair), 'CODE', 'kons lambda code reference returns pair as code reference';
    is $kar->($pair), 23, 'kar applied to pair returns first value';
    is $kdr->($pair), 42, 'kdr applied to pair returns second value';
}

sub T200_direct_application: Tests {

    is self->run('((lambda (n) n) 23)'), 23, 'direct lambda application returned passed value';
}

sub T300_multi_params_with_rest {
    my $self = self;

    is self->run('((lambda (x y . z) x) 1 2 3 4)'), 1, 'first parameter of semi complex signature correct';
    is self->run('((lambda (x y . z) y) 1 2 3 4)'), 2, 'second parameter of semi complex signature correct';
    is_deeply self->run('((lambda (x y . z) z) 1 2 3 4)'), [3, 4], 'rest parameter of semi complex signature correct';

    throws_ok { $self->run('(lambda (x . y z) x)') } 'Script::SXC::Exception::ParseError', 
        'too many rest parameters for lambda throws parse error';
    like $@, qr/too many/i, 'error message contains "too many" part';
    like $@, qr/rest/i, 'error message contains "rest"';

    throws_ok { $self->run('(lambda (x .) x)') } 'Script::SXC::Exception::ParseError', 'missing rest parameter throws parse error';
    like $@, qr/rest/i, 'error message contains "rest"';
}

sub T310_lambda_alias: Tests {

    is self->run('((λ (n) n) 23)'), 23, 'lambda shortcut λ works';
}

sub T350_general_exceptions: Tests {
    my $self = self;

    throws_ok { $self->run('(lambda)') } 'Script::SXC::Exception::ParseError', 'lambda without arguments throws parse error';
    throws_ok { $self->run('(lambda n)') } 'Script::SXC::Exception::ParseError', 'lambda with only one argument throws parse error';
    throws_ok { $self->run('(lambda 23 42)') } 'Script::SXC::Exception::ParseError', 'lambda with invalid signature throws parse error';
}

sub T400_extended_param_spec: Tests {
    my $self = self;

    is_deeply self->run('((lambda ((foo) (bar)) (list foo bar)) 2 3)'), [2, 3], 
        'lambda with extended signature but only names compiles';

    throws_ok { $self->run('(lambda ((:foo)) 23)') } 'Script::SXC::Exception::ParseError', 
        'invalid parameter name throws parse error';
    like $@, qr/parameter name/i, 'error message contains "parameter name"';

    throws_ok { $self->run('(lambda ((foo :fnord)) foo)') } 'Script::SXC::Exception::ParseError', 
        'invalid parameter option throws parse error';
    like $@, qr/parameter option/i, 'error message contains "parameter option"';

    throws_ok { $self->run('(lambda ((foo :where)) foo)') } 'Script::SXC::Exception::ParseError', 
        'missing expression to where clause throws parse error';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/where clause/i, 'error message contains "where clause"';
    like $@, qr/foo/, 'error message contains parameter name';

    throws_ok { $self->run('(lambda ((foo :where 2 3)) foo)') } 'Script::SXC::Exception::ParseError',
        'too many arguments for where clause throw parse error';
    like $@, qr/too many/i, 'error message contains "too many"';
    like $@, qr/where clause/i, 'error message contains "where clause"';
    like $@, qr/foo/, 'error message contains parameter name';
}

sub T405_where_clause: Tests {   
    my $self = self;

    my $lambda = self->run('(lambda ((foo :where (size foo)) . (rest :where (size rest))) (list foo rest))');
    is ref($lambda), 'CODE', 'lambda with where clauses on parameters compiles';
    is_deeply $lambda->([1, 2, 3], 4, 5, 6), [[1, 2, 3], [4, 5, 6]], 'lambda with where clause on params returns correct value';

    throws_ok { $lambda->([]) } 'Script::SXC::Exception::ArgumentError', 'unmet where clauses throw argument error';
    like $@, qr/foo/i, 'error message contains parameter name';

    throws_ok { $lambda->([1, 2]) } 'Script::SXC::Exception::ArgumentError', 'unmet where clause on rest parameter throws argument error';
    like $@, qr/rest/i, 'error message contains rest parameter name';

    throws_ok { $lambda->([], 2, 3) } 'Script::SXC::Exception::ArgumentError', 
        'unmet where clause with other met where clauses throws argument error';
    like $@, qr/foo/i, 'error message contains correct parameter name';
}

sub T410_extended_rest: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (x rest: y) (list x y))')), 'CODE', 'lambda with extended rest compiles';
    is_deeply $lambda->(1, 2, 3), [1, [2, 3]], 'lambda with extended rest sets correct values';
    is_deeply $lambda->(1), [1, []], 'lambda with extended empty rest sets correct values';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'missing mandatory argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(lambda (x rest: y z) x)') } 'Script::SXC::Exception', 'more than one rest parameter throws exception';
    like $@, qr/rest/i, 'error message contains "missing"';

    throws_ok { $self->run('(lambda (x rest:) x)') } 'Script::SXC::Exception', 'missing rest parameter throws exception';
    like $@, qr/rest/i, 'error message contains "missing"';
}

sub T415_optional: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (a b optional: c d) (list a b c d))')), 'CODE', 'lambda with optionals compiles';
    is_deeply $lambda->(1, 2, 3, 4), [1, 2, 3, 4], 'lambda with optional and all specified returns correct values';
    is_deeply $lambda->(1, 2, 3), [1, 2, 3, undef], 'lambda with optional and some specified returns correct values';
    is_deeply $lambda->(1, 2), [1, 2, undef, undef], 'lambda with optional and none specified returns correct value';

    throws_ok { $lambda->(1) } 'Script::SXC::Exception', 'lambda with optional but missing mandatory throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $lambda->(1 .. 5) } 'Script::SXC::Exception', 'lambda with optional but too many throws exception';
    like $@, qr/too\s+many/i, 'error message contains "too many"';
}

sub T420_optional_with_rest: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (a optional: b rest: c) (list a b c))')), 'CODE', 'lambda with optional and rest compiles';
    is_deeply $lambda->(1), [1, undef, []], 'lambda with optional and rest returns correct values with only mandatory';
    is_deeply $lambda->(1, 2), [1, 2, []], 'lambda with optional and rest returns correct values with mandatory and optional';
    is_deeply $lambda->(1, 2, 3), [1, 2, [3]], 'lambda with optional and rest returns correct values with all set';
    is_deeply $lambda->(1..4), [1, 2, [3, 4]], 'lambda with optional and rest returns correct values with additional rest'; 

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'lambda with optional and rest with missing mandatory arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T425_named: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (named: bar baz) (list bar baz))')), 'CODE', 'lambda with named parameters compiles';
    is_deeply $lambda->(bar => 2, baz => 3), [2, 3], 'lambda with named parameters returns correct values';

    throws_ok { $lambda->(bar => 2) } 'Script::SXC::Exception', 'lambda with missing named arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/baz/, 'error message contains missing argument name';

    throws_ok { $lambda->(23, bar => 2, baz => 3) } 'Script::SXC::Exception', 'lambda with too many arguments throws exception';
    like $@, qr/too\s+many/i, 'error message contains "too many"';

    throws_ok { $lambda->(bar => 3, baq => 9) } 'Script::SXC::Exception', 'lambda with named catches typo and throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T430_named_with_rest: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (named: foo rest: bar) (list foo bar))')), 'CODE',
        'lambda with named and rest compiles';
    is_deeply $lambda->(foo => 2, bar => 3), [2, { bar => 3 }],
        'lambda with named and rest returns correct values';
    is_deeply $lambda->(foo => 2, bar => 3, baz => 4), [2, { bar => 3, baz => 4 }],
        'lambda with named and multiple rest returns correct values';
    is_deeply $lambda->(foo => 2), [2, {}],
        'lambda with named and no rest returns correct values';

    throws_ok { $lambda->(fox => 3) } 'Script::SXC::Exception', 'lambda with named and rest throws exception on typo for mandatory';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/foo/, 'error message contains missing argument name';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'lambda with named and rest throws exception without arguments';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/foo/, 'error message contains missing argument name';
}

sub T435_combined: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (foo named: bar) (list foo bar))')), 'CODE', 
        'lambda with combined parameters compiles';
    is_deeply $lambda->(23, bar => 42), [23, 42], 'lambda with combined parameters returns correct values';
    
    throws_ok { $lambda->(23) } 'Script::SXC::Exception', 'lambda with combined but only fixed arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing argument name';

    throws_ok { $lambda->(23, 'bar') } 'Script::SXC::Exception', 'lambda with combined but missing named value throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'lambda with combined but no arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing argument name';

    throws_ok { $lambda->(23, bar => 777, 17) } 'Script::SXC::Exception', 'lambda with combined but too many throws exception';
    like $@, qr/too\s+many/i, 'error message contains "too many"';

    throws_ok { $lambda->(23, baz => 777) } 'Script::SXC::Exception', 'lambda with combined catches typo';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing argument name';
}

sub T440_combined_with_rest: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (foo named: bar rest: baz) (list foo bar baz))')), 'CODE',
        'lambda with combined and rest compiles';
    is_deeply $lambda->(1, bar => 2, baz => 3), [1, 2, { baz => 3 }], 'lambda with combined and rest returns correct values';
    is_deeply $lambda->(1, bar => 2), [1, 2, {}], 'lambda with combined and no rest returns correct values';
    
    throws_ok { $lambda->(23) } 'Script::SXC::Exception', 'lambda with combined and rest but only fixed arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing argument name';

    throws_ok { $lambda->(23, 'bar') } 'Script::SXC::Exception', 'lambda with combined but missing named value throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'lambda with combined but no arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing argument name';

    throws_ok { $lambda->(23, baz => 777) } 'Script::SXC::Exception', 'lambda with combined catches typo';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing argument name';
}

sub T445_named_and_optional: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (named: foo optional: bar) (list foo bar))')), 'CODE',
        'lambda with named and optionals compiles';
    is_deeply $lambda->(foo => 3, bar => 4), [3, 4], 'lambda with named and optionals returns correct values';
    is_deeply $lambda->(foo => 3), [3, undef], 'lambda with named and not specified optional returns correct values';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'lambda with named and optionals but missing values throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/foo/, 'error message contains missing argument name';

    throws_ok { $lambda->('foo') } 'Script::SXC::Exception', 'lambda with named and optionals but missing named values throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $lambda->(foo => 7, baz => 9) } 'Script::SXC::Exception', 'lambda with named and optionals but typo throws exception';
    like $@, qr/unknown/i, 'error message contains "unknown"';
    like $@, qr/baz/, 'error message contains missing argument name';

    throws_ok { $lambda->(foo => 3, bar => 8, qux => 9) } 'Script::SXC::Exception', 
        'lambda with named and optinoals but too many throws exception';
    like $@, qr/too\s+many/i, 'error message contains "too many"';
}

sub T450_named_and_optional_with_rest: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (named: foo optional: bar rest: baz) (list foo bar baz))')), 'CODE',
        'lambda with named and optionals with rest compiles';
    is_deeply $lambda->(foo => 3, bar => 4, baz => 5), [3, 4, { baz => 5 }], 
        'lambda with named and optionals with rest returns correct values';
    is_deeply $lambda->(foo => 3, bar => 4), [3, 4, {}],
        'lambda with named and optionals without rest returns correct values';
    is_deeply $lambda->(foo => 3), [3, undef, {}],
        'lambda with named and no optionals or rest returns correct values';
    is_deeply $lambda->(foo => 3, baz => 4), [3, undef, { baz => 4 }],
        'lambda with named and no optionals but rest returns correct values';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 
        'lambda with named and optionals with rest throws exception without arguments';
    like $@, qr/missing/i, 'error message contains "message"';
    like $@, qr/foo/, 'error message contains missing mandatory argument name';

    throws_ok { $lambda->(fox => 23) } 'Script::SXC::Exception', 'lambda with named and optionals and rest catches typo';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/foo/, 'error message contains missing mandatory argument name';
}

sub T455_combined_with_optional: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (foo named: bar optional: baz) (list foo bar baz))')), 'CODE',
        'lambda with combined and optional compiles';
    is_deeply $lambda->(23, bar => 17, baz => 33), [23, 17, 33], 
        'lambda with combined and optional returns correct value';
    is_deeply $lambda->(23, bar => 17), [23, 17, undef],
        'lambda with combined but no optionals returns correct value';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 
        'lambda with combined and optionals throws exception without arguments';
    like $@, qr/missing/i, 'error message contains "message"';

    throws_ok { $lambda->(23) } 'Script::SXC::Exception', 
        'lambda with combined and optionals with missing named throws exception without arguments';
    like $@, qr/missing/i, 'error message contains "message"';
    like $@, qr/bar/, 'error message contains missing mandatory argument name';

    throws_ok { $lambda->(23, bax => 17) } 'Script::SXC::Exception', 
        'lambda with combined and optionals with typo throws exception without arguments';
    like $@, qr/missing/i, 'error message contains "message"';
    like $@, qr/bar/, 'error message contains missing mandatory argument name';

    throws_ok { $lambda->(23, bar => 17, bax => 77) } 'Script::SXC::Exception', 
        'lambda with combined and optionals with typo in optional throws exception without arguments';
    like $@, qr/unknown/i, 'error message contains "unknown"';
    like $@, qr/bax/, 'error message contains missing mandatory argument name';

    is ref(my $lambda2 = self->run('(lambda (foo optional: bar named: baz) (list foo bar baz))')), 'CODE',
        'lambda with combined and fixed optionals compiles';
    is_deeply $lambda2->(3, 4, baz => 5), [3, 4, 5], 
        'lambda with combined and fixed optionals returns correct values';
    is_deeply $lambda2->(3, 4), [3, 4, undef],
        'lambda with combined and fixed optionals without named returns correct values';
    is_deeply $lambda2->(3), [3, undef, undef],
        'lambda with combined and fixed optionals with only mandatory returns correct values';

    throws_ok { $lambda2->() } 'Script::SXC::Exception', 
        'lambda with combined and fixed optionals throws exception without arguments';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $lambda2->(3, 4, baz => 7, bax => 8) } 'Script::SXC::Exception',
        'lambda with combined and fixed optionals throws exception with too many arguments';
    like $@, qr/too\s+many/i, 'error message contains "too many"';

    throws_ok { $lambda2->(3, 4, bax => 9) } 'Script::SXC::Exception',
        'lambda with combined and fixed optionals throws exception with typo';
    like $@, qr/unknown/i, 'error message contains "unknown"';
    like $@, qr/bax/, 'error message contains unknown argument name';
}

sub T460_combined_with_optional_and_rest: Tests {
    my $self = self;

    is ref(my $lambda = self->run('(lambda (foo named: bar optional: baz rest: qux) (list foo bar baz qux))')), 'CODE',
        'lambda with combined and optional and rest compiles';
    is_deeply $lambda->(23, bar => 17, baz => 33, qux => 44), [23, 17, 33, { qux => 44 }], 
        'lambda with combined and optional and rest returns correct value';
    is_deeply $lambda->(23, bar => 17, baz => 33), [23, 17, 33, {}], 
        'lambda with combined and optional but no rest returns correct value';
    is_deeply $lambda->(23, bar => 17), [23, 17, undef, {}],
        'lambda with combined but no optionals or rest returns correct value';
    is_deeply $lambda->(23, bar => 17, qux => 44), [23, 17, undef, { qux => 44 }],
        'lambda with combined and no optionals but rest returns correct values';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 
        'lambda with combined and optional and rest but no arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $lambda->(23) } 'Script::SXC::Exception',
        'lambda with combined and optional and rest but only fixed value throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing named argument name';

    throws_ok { $lambda->(23, 17) } 'Script::SXC::Exception',
        'lambda with combined and optional and rest but non named named argument throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing named argument name';
    
    throws_ok { $lambda->(23, bax => 17) } 'Script::SXC::Exception',
        'lambda with combined and optional and rest but typo throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
    like $@, qr/bar/, 'error message contains missing named argument name';

    is ref($lambda = self->run('(lambda (foo optional: bar named: baz rest: qux) (list foo bar baz qux))')), 'CODE',
        'lambda with combined and optional reversed compiles';
    is_deeply $lambda->(23), [23, undef, undef, {}],
        'lambda with combined and optional reversed returns correct values with only mandatory argument';
    is_deeply $lambda->(23, 17), [23, 17, undef, {}],
        'lambda with combined and optional reversed returns correct values with mandatory and optional fixed arguments';
    is_deeply $lambda->(23, 17, baz => 99), [23, 17, 99, {}],
        'lambda with combined and optional reversed returns correct values with all but rest';
    is_deeply $lambda->(23, 17, baz => 99, qux => 77), [23, 17, 99, { qux => 77 }],
        'lambda with combined and optional reversed returns correct values with all';
    is_deeply $lambda->(23, 17, qux => 77), [23, 17, undef, { qux => 77 }],
        'lambda with combined and optional reversed returns correct values with rest but no named';

    throws_ok { $lambda->() } 'Script::SXC::Exception', 
        'lambda with combined and optional reversed and rest but no arguments throws exception';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T500_arg_count_with_rest: Tests {
    my $self = self;

    my $with_rest = self->run('(lambda (a b . c) (list a b c))');
    is ref($with_rest), 'CODE', 'test function for argument count check with rest compiles';
    is_deeply $with_rest->(1, 2, 3, 4), [1, 2, [3, 4]], 'valid call with optional rest receives correct arguments';
    is_deeply $with_rest->(1, 2), [1, 2, []], 'valid call without optional rest receives correct arguments';

    throws_ok { $with_rest->(1) } 'Script::SXC::Exception::ArgumentError', 'missing argument throws argument error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $with_rest->() } 'Script::SXC::Exception::ArgumentError', 'missing arguments throw argument error';
    like $@, qr/missing/i, 'error message contains "missing"';
}

sub T510_arg_count_fixed: Tests {
    my $self = self;

    my $without_rest = self->run('(lambda (a b) (list a b))');
    is ref($without_rest), 'CODE', 'test function for argument count check without rest compiles';
    is_deeply $without_rest->(1, 2), [1, 2], 'valid call to function without rest receives correct arguments';

    throws_ok { $without_rest->(1) } 'Script::SXC::Exception::ArgumentError', 'missing argument throws argument error';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $without_rest->(1, 2, 3) } 'Script::SXC::Exception::ArgumentError', 'too many arguments throw exception';
    like $@, qr/too many/i, 'error message contains "too many"';
}

sub T600_undefined_arguments: Tests {
    my $self   = self;
    my $lambda = self->run('(lambda (foo optional: bar) (list foo bar))');

    lives_ok {
        is_deeply $lambda->(undef, undef), [undef, undef], 'undefined mandatory and optional arguments return correct values';
        is_deeply $lambda->(undef), [undef, undef], 'undefined mandatory and not specified optional arguments return correct values';
    };

    throws_ok { $lambda->() } 'Script::SXC::Exception', 'missing mandatory argument still throws exception';
}

sub T800_chunks: Tests {
    my $self = self;

    for my $name (qw( chunk λ… )) {

        is ref(self->run("($name 23)")), 'CODE', "$name builds successful code reference";
        is self->run("(($name 23))"), 23, "$name returns evaluated body expression on call";

        throws_ok { $self->run("($name)") } 'Script::SXC::Exception', "$name without body throws exception";
        like $@, qr/$name/, qq(error message contains "$name");
        like $@, qr/missing/i, 'error message contains "missing"';
    }
}

sub T850_arrow_function: Tests {
    my $self = self;

    is ref(self->run('(-> 23)')), 'CODE', '-> builds code reference';
    is self->run('((-> _) 23)'), 23, '-> binds _ correctly';
    is self->run('((-> (+ _ 10)) 13)'), 23, '-> built function returns correct result';

    throws_ok { $self->run("(->)") } 'Script::SXC::Exception', "-> without body throws exception";
    like $@, qr/->/, qq(error message contains "->");
    like $@, qr/missing/i, 'error message contains "missing"';

    is_deeply self->run('(map (list 2 3 4) (-> (* _ 2)))'), [4, 6, 8], '-> in combination with map returns correct list';
}

1;
