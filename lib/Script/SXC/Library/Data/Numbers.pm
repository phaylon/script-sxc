package Script::SXC::Library::Data::Numbers;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime::Validation;
use Script::SXC::Exception::ArgumentError;
use Script::SXC::lazyload
    'Script::SXC::Exception::ArgumentError',
    'Script::SXC::Compiler::Environment::Variable',
    [qw( Script::SXC::Compiled::Value   CompiledValue )];

use Data::Dump qw( pp );

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('sqrt',
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('sqrt', [@_], min => 1, max => 1);
        return sqrt shift;
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner     => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(
            typehint => 'number',
            content  => sprintf 'sqrt(%s)', $exprs->[0]->compile($compiler, $env)->render,
        );
    },
);

CLASS->add_procedure('+',
    firstclass => sub { my $sum = 0; $sum += $_ for @_; return $sum },
    inline_fc  => 1,
    inliner    => CLASS->build_joining_operator('+'),
);

CLASS->add_procedure('-',
    firstclass => sub { return 0 unless @_; my $sum = shift; $sum -= $_ for @_; return $sum },
    inline_fc  => 1,
    inliner    => CLASS->build_joining_operator('-'),
);

CLASS->add_procedure('*',
    firstclass => sub { return 0 unless @_; my $sum = shift; $sum *= $_ for @_; return $sum },
    inline_fc  => 1,
    inliner    => CLASS->build_joining_operator('*'),
);

CLASS->add_procedure('/',
    firstclass => sub {
        return 0 unless @_;
        Script::SXC::Exception::ArgumentError->throw_to_caller(
            type        => 'division_by_zero',
            message     => 'Illegal division by zero',
        ) if scalar grep { $_ == 0 } @_;
        my $sum = shift;
        $sum /= $_ for @_;
        return $sum;
    },
    inline_fc => 1,
    runtime_req => ['Validation', '+Script::SXC::Exception::ArgumentError'],
    inliner => CLASS->build_joining_operator('/',
        around_args => sub {
            my ($expr, $compiler, $env) = @_;
            my $var = Variable->new_anonymous('divzero_test');
            $compiler->add_required_package(ArgumentError);
            return sprintf '(do { my %s = %s; %s->throw(%s) if %s == 0; %s })',
                $var->render,
                $expr->compile($compiler, $env)->render,
                ArgumentError,
                pp( type    => 'division_by_zero',
                    message => 'Illegal division by zero',
                    $expr->source_information,
                ),
                $var->render,
                $var->render;
        },
    ),
);

CLASS->add_procedure('++', 
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('++', [@_], min => 1, max => 1);
        return $_[0] + 1;
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf '(%s + 1)', $exprs->[0]->compile($compiler, $env)->render);
    },
);

CLASS->add_procedure('--', 
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('--', [@_], min => 1, max => 1);
        return $_[0] - 1;
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf '(%s - 1)', $exprs->[0]->compile($compiler, $env)->render);
    },
);

CLASS->add_procedure([qw( == = )],
    firstclass  => CLASS->build_firstclass_equality_operator('==', sub { $_[0] == $_[1] }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_equality_operator('=='),
);

CLASS->add_procedure('!=',
    firstclass  => CLASS->build_firstclass_nonequality_operator('!=', sub { $_[0] != $_[1] }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_nonequality_operator('!='),
);

CLASS->add_procedure('<',
    firstclass  => CLASS->build_firstclass_sequence_operator('<', sub { $_[0] < $_[1] }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_sequence_operator('<'),
);

CLASS->add_procedure('>',
    firstclass  => CLASS->build_firstclass_sequence_operator('>', sub { $_[0] > $_[1] }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_sequence_operator('>'),
);

CLASS->add_procedure('<=',
    firstclass  => CLASS->build_firstclass_sequence_operator('<=', sub { $_[0] <= $_[1] }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_sequence_operator('<='),
);

CLASS->add_procedure('>=',
    firstclass  => CLASS->build_firstclass_sequence_operator('>=', sub { $_[0] >= $_[1] }),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_sequence_operator('>='),
);

CLASS->add_procedure('abs',
    firstclass  => sub { 
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('abs', [@_], min => 1, max => 1);
        return abs shift;
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf 'abs(%s)', $exprs->[0]->compile($compiler, $env)->render);
    },
);

CLASS->add_procedure('mod',
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('mod', [@_], min => 2, max => 2);
        return $_[0] % $_[1];
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        # TODO single arg optimisation
        return CompiledValue->new(content => sprintf
            '(%s %% %s)',
            map { $_->compile($compiler, $env)->render } @$exprs,
        );
    },
);

CLASS->add_procedure('odd?',
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('odd?', [@_], min => 1);
        $_ % 2 or return undef
            for @_;
        return 1;
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        # TODO single arg optimisation
        return CompiledValue->new(typehint => 'bool', content => sprintf
            '( not(grep { not($_ %% 2) } (%s)) ? 1 : undef )',
            join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
        );
    },
);

CLASS->add_procedure('even?',
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('even?', [@_], min => 1);
        not($_ % 2) or return undef
            for @_;
        return 1;
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        # TODO single arg optimisation
        return CompiledValue->new(typehint => 'bool', content => sprintf
            '( not(grep { $_ %% 2 } (%s)) ? 1 : undef )',
            join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
        );
    },
);

CLASS->add_procedure('max',
    firstclass  => CLASS->build_direct_firstclass('List::Util', 'max', min => 1),
    inline_fc   => 1,
    inliner     => CLASS->build_direct_inliner('List::Util', 'max', min => 1),
);

CLASS->add_procedure('min',
    firstclass  => CLASS->build_direct_firstclass('List::Util', 'min', min => 1),
    inline_fc   => 1,
    inliner     => CLASS->build_direct_inliner('List::Util', 'min', min => 1),
);

__PACKAGE__->meta->make_immutable;

1;
