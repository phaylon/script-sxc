package Script::SXC::Test::Library::Core::Lambdas;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use self;
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T200_lambdas: Tests {
    my $self = self;

    # simple without scoping tests
    {   my $lambda = self->run('(lambda () 23)');
        is ref($lambda), 'CODE', 'simple lambda returned code reference';
        is $lambda->(), 23, 'execution of lambda returned evaluated body expression';
    }

    # simple with list param
    {   my $lambda = self->run('(lambda foo 23)');
        is ref($lambda), 'CODE', 'lambda with list parameter returned code reference';
        is $lambda->(), 23, 'execution of lambda returned evaluated body expression';
    }

    # simple with one param
    {   my $lambda = self->run('(lambda (n) 23)');
        is ref($lambda), 'CODE', 'lambda with one parameter returned code reference';
        is $lambda->(42), 23, 'execution of lambda returned evaluated body expression';
    }

    # simple with one param and environment access
    {   my $lambda = self->run('(lambda (n) n)');
        is ref($lambda), 'CODE', 'lambda with one parameter returned code reference';
        is $lambda->(777), 777, 'lambda with one parameter and local environment access returns passed value';
    }

    # be one with the cons
    {   my $kons = self->run('(lambda (n m) (lambda (f) (f n m)))');
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

    # direct lambda application
    is self->run('((lambda (n) n) 23)'), 23, 'direct lambda application returned passed value';

    # two parameters and a rest
    is self->run('((lambda (x y . z) x) 1 2 3 4)'), 1, 'first parameter of semi complex signature correct';
    is self->run('((lambda (x y . z) y) 1 2 3 4)'), 2, 'second parameter of semi complex signature correct';
    is_deeply self->run('((lambda (x y . z) z) 1 2 3 4)'), [3, 4], 'rest parameter of semi complex signature correct';
    throws_ok { $self->run('(lambda (x . y z) x)') } 'Script::SXC::Exception::ParseError', 
        'too many rest parameters for lambda throws parse error';
    like $@, qr/too many/i, 'error message contains "too many" part';
    like $@, qr/rest/i, 'error message contains "rest"';
    throws_ok { $self->run('(lambda (x .) x)') } 'Script::SXC::Exception::ParseError', 'missing rest parameter throws parse error';
    like $@, qr/rest/i, 'error message contains "rest"';

    # lambda λ alias
    is self->run('((λ (n) n) 23)'), 23, 'lambda shortcut λ works';

    # general exceptions
    throws_ok { $self->run('(lambda)') } 'Script::SXC::Exception::ParseError', 'lambda without arguments throws parse error';
    throws_ok { $self->run('(lambda n)') } 'Script::SXC::Exception::ParseError', 'lambda with only one argument throws parse error';
    throws_ok { $self->run('(lambda 23 42)') } 'Script::SXC::Exception::ParseError', 'lambda with invalid signature throws parse error';

    # extended parameter specifications
    is_deeply self->run('((lambda ((foo) (bar)) (list foo bar)) 2 3)'), [2, 3], 'lambda with extended signature but only names compiles';
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

    # where
    {   my $lambda = self->run('(lambda ((foo :where (size foo)) . (rest :where (size rest))) (list foo rest))');
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

    # argument count
    {   my $with_rest = self->run('(lambda (a b . c) (list a b c))');
        is ref($with_rest), 'CODE', 'test function for argument count check with rest compiles';
        is_deeply $with_rest->(1, 2, 3, 4), [1, 2, [3, 4]], 'valid call with optional rest receives correct arguments';
        is_deeply $with_rest->(1, 2), [1, 2, []], 'valid call without optional rest receives correct arguments';
        throws_ok { $with_rest->(1) } 'Script::SXC::Exception::ArgumentError', 'missing argument throws argument error';
        like $@, qr/missing/i, 'error message contains "missing"';
        throws_ok { $with_rest->() } 'Script::SXC::Exception::ArgumentError', 'missing arguments throw argument error';
        like $@, qr/missing/i, 'error message contains "missing"';
    }
    {   my $without_rest = self->run('(lambda (a b) (list a b))');
        is ref($without_rest), 'CODE', 'test function for argument count check without rest compiles';
        is_deeply $without_rest->(1, 2), [1, 2], 'valid call to function without rest receives correct arguments';
        throws_ok { $without_rest->(1) } 'Script::SXC::Exception::ArgumentError', 'missing argument throws argument error';
        like $@, qr/missing/i, 'error message contains "missing"';
        throws_ok { $without_rest->(1, 2, 3) } 'Script::SXC::Exception::ArgumentError', 'too many arguments throw exception';
        like $@, qr/too many/i, 'error message contains "too many"';
    }
}

1;
