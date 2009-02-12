package Script::SXC::Library::Data::Lists;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime;
use Script::SXC::Runtime::Validation;

use List::Util      qw( min max );
use List::MoreUtils qw( any all none );

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    'Script::SXC::Exception::ParseError',
    [qw( Script::SXC::Compiled::Value               CompiledValue )],
    [qw( Script::SXC::Compiled::TypeCheck           CompiledTypeCheck )],
    [qw( Script::SXC::Compiled::TypeSwitch          CompiledTypeSwitch )],
    [qw( Script::SXC::Compiled::Application::List   CompiledListApplication )],
    [qw( Script::SXC::Compiled::Iteration           CompiledIteration )],
    [qw( Script::SXC::Compiled::Application         CompiledApplication )];

use constant BuiltinClass   => 'Script::SXC::Tree::Builtin';
use constant KeywordClass   => 'Script::SXC::Tree::Keyword';
use constant InlinerClass   => 'Script::SXC::Library::Item::Inliner';
use constant ProcedureClass => 'Script::SXC::Library::Item::Procedure';

use CLASS;
use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

method build_inline_list_application (Str $keyword!, ArrayRef :$required_packages = [], Str :$surround_template?, Str :$typehint?) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        my ($ls, $apply) = @$exprs;
        my $curr = Variable->new_anonymous('listapply_curr_val');
        $surround_template //= '[ %s ]';
        $compiler->add_required_package($_)
            for @$required_packages;
        return CompiledValue->new( ( $typehint ? (typehint => $typehint) : () ), content => 
            sprintf $surround_template,
            sprintf '(%s { my %s = $_; %s } %s)',
            $keyword,
            $curr->render,
            CompiledApplication->new_from_uncompiled(
                $compiler,
                $env,
                invocant                => $apply,
                arguments               => [$curr],
                return_type             => 'scalar',
                inline_invocant         => 1,
                inline_firstclass_args  => 0,
                options => {
                    optimize_tailcalls  => 0,
                    first_class         => $compiler->force_firstclass_procedures,
                    source              => $apply,
                },
                $apply->source_information,
            )->render,
            sprintf('(@{( %s )})',
                CompiledTypeCheck->new(
                    expression              => $ls->compile($compiler, $env),
                    type                    => 'list',
                    source_item             => $ls,
                    message                 => $name . ' needs a list as first argument',
                )->render,
            ),
        );
    }
}

CLASS->add_procedure('range',
    firstclass  => CLASS->build_direct_firstclass('Script::SXC::Runtime', 'range', min => 1, max => 4),
    inline_fc   => 1,
    inliner     => CLASS->build_direct_inliner('Script::SXC::Runtime', 'range', min => 1, max => 4, typehint => 'list'),
);

CLASS->add_procedure('for',
    firstclass => sub ($ls, $appl) {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('for', [@_], min => 2, max => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'for expects list as first argument');
        my $last;
        my $iterator = Script::SXC::Runtime::make_iterator($ls);
        until ($iterator->is_end($iterator->next_step)) {
            $last = $iterator->apply_current($appl);
        }
        return $last;
    },
    inline_fc => 1,
    runtime_req => ['Validation', '+Script::SXC::Runtime'],
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        my ($ls, $apply) = @$exprs;
        my $last_var = Variable->new_anonymous('last_value');
        my $curr_var = Variable->new_anonymous('current_value');
        return CompiledIteration->new(
            compiled_source => $ls->compile($compiler, $env),
            source_item     => $symbol,
            compile_body    => method (Object $iterator_var) {
                return sprintf(
                    '(do { my %s; until(%s->is_end(my %s = %s->next_step)) { %s = %s } %s })',
                    $last_var->render,
                    $iterator_var->render,
                    $curr_var->render,
                    $iterator_var->render,
                    $last_var->render,
                    CompiledApplication->new_from_uncompiled(
                        $compiler,
                        $env,
                        invocant                => $apply,
                        arguments               => [$curr_var],
                        return_type             => 'scalar',
                        inline_invocant         => 1,
                        inline_firstclass_args  => 0,
                        options => {
                            optimize_tailcalls  => 0,
                            first_class         => $compiler->force_firstclass_procedures,
                            source              => $apply,
                        },
                        $apply->source_information,
                    )->render,
                    $last_var->render,
                );
            },
        );
    },
);

CLASS->add_procedure('list', 
    firstclass  => sub { [@_] },
    inline_fc   => 1,
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {
        return CompiledValue->new(
            content  => sprintf('[( %s )]', join(', ', map { $_->compile($compiler, $env)->render } @$exprs)),
            typehint => 'list',
        );
    },
);

CLASS->add_procedure('head',
    firstclass  => sub ($ls, $num) {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('head', [@_], min => 1, max => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'head expects list as first argument');
        $num-- if defined $num;
        if (Scalar::Util::blessed($ls) and $ls->isa('Script::SXC::Runtime::Range')) {
            my $iterator = $ls->to_iterator;
            if (defined $num) {
                my @head;
                my $count = 0;
                until ($iterator->is_end($iterator->next_step)) {
                    $count++;
                    push @head, $iterator->current_value;
                    last if $count >= $num;
                }
                return \@head;
            }
            else {
                $iterator->is_end(my $value = $iterator->next_step)
                    and return undef;
                return $value;
            }
        }
        return defined $num 
            ? [ @$ls[0 .. List::Util::min($num, $#$ls)] ]
            : ( @$ls ? $ls->[0] : undef );
    },
    inline_fc   => 1,
    runtime_req => ['Validation', '+List::Util', '+Scalar::Util'],
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 2);
        my ($ls, $num) = @$exprs;

        if (@$exprs == 1) {
            return CompiledTypeSwitch->new(
                source_item => $ls,
                expression  => CompiledTypeCheck->new(
                    expression  => $ls->compile($compiler, $env),
                    type        => 'list',
                    source_item => $ls,
                    message     => 'first argument to head must be a list',
                ),
                typemap     => {
                    range       => do {
                        my $iterator_var = Variable->new_anonymous('iterator');
                        my $value_var    = Variable->new_anonymous('head_value');
                        sprintf(
                            '(do { my %s = (%s)->to_iterator; my %s = %s->next_step; %s->is_end(%s) ? undef : %s })',
                            $iterator_var->render,
                            '%s',
                            $value_var->render,
                            $iterator_var->render,
                            $iterator_var->render,
                            $value_var->render,
                            $value_var->render,
                        )
                    },
                    list => '( (%s)->[0] )',
                },
            );
        }
        else {
            return CompiledValue->new(typehint => 'list', content => CompiledTypeSwitch->new(
                source_item => $ls,
                expression  => CompiledTypeCheck->new(
                    expression  => $ls->compile($compiler, $env),
                    type        => 'list',
                    source_item => $ls,
                    message     => 'first argument to head must be a list',
                ),
                typemap     => {
                    range       => do {
                        my $iterator_var = Variable->new_anonymous('iterator');
                        my $values_var   = Variable->new_anonymous('head_values', sigil => '@');
                        my $value_var    = Variable->new_anonymous('head_value');
                        my $count_var    = Variable->new_anonymous('head_count');
                        my $num_var      = Variable->new_anonymous('head_num');
                        sprintf(
                '(do { my %s = (%s)->to_iterator; my %s = 0; my %s = %s; my %s; until (%s) { last if %s >= %s; push %s, %s; %s++ }; [%s] })',
                            $iterator_var->render,
                            '%s',
                            $count_var->render,
                            $num_var->render,
                            $num->compile($compiler, $env)->render,
                            $values_var->render,
                            sprintf(
                                '%s->is_end(my %s = %s->next_step)',
                                $iterator_var->render,
                                $value_var->render,
                                $iterator_var->render,
                            ),
                            $count_var->render,
                            $num_var->render,
                            $values_var->render,
                            $value_var->render,
                            $count_var->render,
                            $values_var->render,
                        );
                    },
                    list => do {
                        my $ls_var  = Variable->new_anonymous('head_list');
                        my $num_var = Variable->new_anonymous('head_num');
                        sprintf(
                            'do { my %s = %s; my %s = %s; [ @{( %s )}[0 .. (@{%s} > %s ? %s : scalar(@{%s})) - 1] ] }',
                            $ls_var->render,
                            '%s',
                            $num_var->render,
                            $num->compile($compiler, $env)->render,
                            $ls_var->render,
                            $ls_var->render,
                            $num_var->render,
                            $num_var->render,
                            $ls_var->render,
                        );
                    }
                },
            )->render);
        }
    },
);

CLASS->add_procedure('tail',
    firstclass => sub ($ls, $num) {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('tail', [@_], min => 1, max => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'tail expects list as first argument');
        if (Scalar::Util::blessed $ls) {
            if ($ls->isa('Script::SXC::Runtime::Range')) {
                if (defined $num) {
                    $ls = [@$ls];
                    return [ 
                        @$ls[ (@$ls - List::Util::min(scalar(@$ls), $num)) .. $#$ls ] 
                    ];
                }
                else {
                    my $iterator = $ls->to_iterator;
                    $iterator->clear;
                    $iterator->next_step for 1..2;
                    return $iterator->range_from_here;
                }
            }
            else {
                die "Invalid iterator object";
            }
        }
        $num = $#$ls unless defined $num;
        return [ @$ls[ (@$ls - List::Util::min(scalar(@$ls), $num)) .. $#$ls ] ];
    },
    inline_fc   => 1,
    runtime_req => ['Validation', '+List::Util', '+Scalar::Util'],
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 2);
        my ($ls, $num) = @$exprs;

        my $ls_var    = Variable->new_anonymous('tail_list');
        my $num_var   = Variable->new_anonymous('tail_num');
        my $start_var = Variable->new_anonymous('tail_start_at');

        my $to_list_with_num = sprintf(
            'do { my %s = %s; my %s = %s; my %s = %s; [ %s ] }',
            $ls_var->render,
            '%s',
            $num_var->render,
            ( $num ? $num->compile($compiler, $env)->render : '0' ),
            $start_var->render,
            sprintf(
                '( $#{ %s } - (%s - 1) )',
                $ls_var->render,
              ( $num ? $num_var->render : sprintf('$#{ %s }', $ls_var->render) ),
            ),
            sprintf(
                '@{ %s }[ (%s < 0 ? 0 : %s) .. $#{ %s } ]',
                $ls_var->render,
                $start_var->render,
                $start_var->render,
                $ls_var->render,
            ),
        );

        return CompiledTypeSwitch->new(
            expression  => $ls->compile($compiler, $env),
            source_item => $ls,
            typemap     => {
                range => do {
                    my $iterator_var = Variable->new_anonymous('iterator');
                    defined($num)
                    ? $to_list_with_num
                    : sprintf(
                        '(do { my %s = (%s)->to_iterator; %s->clear; %s->next_step for 1..2; %s->range_from_here })',
                        $iterator_var->render,
                        '%s',
                        ($iterator_var->render) x 3,
                      );
                },
                list => $to_list_with_num,
            },
        );


        return CompiledValue->new(content => sprintf(
            'do { my %s = %s; my %s = %s; my %s = %s; [ %s ] }',
            $ls_var->render,
            CompiledTypeCheck->new(
                expression  => $ls->compile($compiler, $env),
                type        => 'list',
                source_item => $ls,
                message     => 'first argument to head must be a list',
            )->render,
            $num_var->render,
            ( $num ? $num->compile($compiler, $env)->render : '0' ),
            $start_var->render,
            sprintf(
                '( $#{ %s } - (%s - 1) )',
                $ls_var->render,
              ( $num ? $num_var->render : sprintf('$#{ %s }', $ls_var->render) ),
            ),
            sprintf(
                '@{ %s }[ (%s < 0 ? 0 : %s) .. $#{ %s } ]',
                $ls_var->render,
                $start_var->render,
                $start_var->render,
                $ls_var->render,
            ),
        ), typehint => 'list');
    },
);

CLASS->add_procedure('size',
    firstclass => sub ($ls) { 
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('size', [@_], min => 1, max => 1);
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'size requires list as argument');
        return scalar @$ls;
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, Str :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

        return CompiledValue->new(
            content  => sprintf('scalar(@{( %s )})',
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'list',
                    source_item => $exprs->[0],
                    message     => 'argument to size must be a list',
                )->render,
            ),
            typehint => 'number',
        );
    },
);

CLASS->add_procedure('last-index',
    firstclass => sub ($ls) { 
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('last-index', [@_], min => 1, max => 1);
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'last-index requires list as argument');
        return $#{ $ls };
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs, :$name, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);

        return CompiledValue->new(
            content  => sprintf('($#{( %s )})', 
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'list',
                    source_item => $exprs->[0],
                    message     => 'argument to last-index must be a list',
                )->render,
            ),
            typehint => 'number',
        );
    },
);

CLASS->add_procedure('list-ref',
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('list-ref', [@_], min => 2, max => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion($_[0], 'list', 'list-ref expects a list as first argument');
        return $_[0]->[ $_[1] ];
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    setter => sub {
        my ($compiler, $env, $args, $expr, $symbol) = @_;
        $symbol->throw_parse_error(missing_setter_args => "Missing arguments: list-ref setter needs list and index arguments")
            if @$args < 2;
        $args->[2]->throw_parse_error(too_many_setter_args => "Too many arguments for list-ref setter")
            if @$args > 2;
        my ($ls, $index) = @$args;
        my $compiled_expr = $expr->compile($compiler, $env);
        return CompiledValue->new(content => sprintf(
            '( (%s)->[%s] = %s )',
            CompiledTypeCheck->new(
                expression  => $ls->compile($compiler, $env),
                source_item => $ls,
                type        => 'list',
                message     => 'list-ref setter expects list as first argument',
            )->render,
            $index->compile($compiler, $env)->render,
            $compiled_expr->render,
        ), ($compiled_expr->can('typehint') ? (typehint => $compiled_expr->typehint) : ()) );
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs, :$name, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);

        return CompiledValue->new(
            content => sprintf('( (%s)->[%s] )', 
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'list',
                    source_item => $exprs->[0],
                    message     => 'first argument to list-ref must be a list',
                )->render,
                $exprs->[1]->compile($compiler, $env)->render,
            ),
        );
    },
);

CLASS->add_procedure('append',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('append', [@_], min => 2);
        Script::SXC::Runtime::Validation->runtime_type_assertion($_[ $_ ], 'list', "Invalid argument $_: append expects only list arguments")
            for 0 .. $#_;
        return [ map { @$_ } @_ ];
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        return CompiledValue->new(content => sprintf(
            '[ %s ]',
            join(', ', map {
                sprintf '(@{( %s )})', CompiledTypeCheck->new(
                    expression  => $exprs->[ $_ ]->compile($compiler, $env),
                    type        => 'list',
                    source_item => $exprs->[ $_ ],
                    message     => "Invalid argument $_: append expects only list arguments",
                )->render,
            } 0 .. $#$exprs),
        ), typehint => 'list');
    },
);

CLASS->add_procedure('list?',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('list?', [@_], min => 1);
        (ref($_) and ref($_) eq 'ARRAY') or (Scalar::Util::blessed($_) and $_->isa('Script::SXC::Runtime::Range')) or return undef
            for @_;
        return 1;
    },
    inline_fc   => 1,
    runtime_req => ['Validation', '+Scalar::Util'],
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        my $anon = Variable->new_anonymous('list_p_arg');
        return CompiledValue->new(content => sprintf(
            '( (%s) or undef )',
            join(
                ' and ',
                map {
                    sprintf 'do { my %s = %s; (ref(%s) and ref(%s) eq q(ARRAY)) or (%s(%s) and %s->isa("%s")) }',
                        $anon->render,
                        $_->compile($compiler, $env)->render,
                        $anon->render,
                        $anon->render,
                        'Scalar::Util::blessed',
                        $anon->render,
                        $anon->render,
                        'Script::SXC::Runtime::Range',
                } @$exprs,
            ),
        ), typehint => 'bool');
    },
);

CLASS->add_procedure('grep',
    inliner     => CLASS->build_inline_list_application('grep', typehint => 'list'),
    inline_fc   => 1,
    runtime_req => ['Validation', '+'],
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('grep', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'grep expects a list as first argument');
        return [ grep { Script::SXC::Runtime::apply($apply, [$_]) } @$ls ];
    },
);

CLASS->add_procedure('map',
    inliner     => CLASS->build_inline_list_application('map', typehint => 'list'),
    inline_fc   => 1,
    runtime_req => ['Validation', '+'],
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('map', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'map expects a list as first argument');
        return [ map { Script::SXC::Runtime::apply($apply, [$_]) } @$ls ];
    },
);

CLASS->add_procedure('count',
    inliner     => CLASS->build_inline_list_application('grep', surround_template => 'scalar(%s)', typehint => 'number'),
    inline_fc   => 1,
    runtime_req => ['Validation', '+'],
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('count', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'count expects a list as first argument');
        return scalar( grep { Script::SXC::Runtime::apply($apply, [$_]) } @$ls );
    },
);

CLASS->add_procedure('any?',
    inliner     => CLASS->build_inline_list_application(
        'List::MoreUtils::any', 
        surround_template => '( (%s) ? 1 : undef )', 
        required_packages => ['List::MoreUtils'],
        typehint          => 'bool',
    ),
    inline_fc   => 1,
    runtime_req => ['Validation', '+', '+List::MoreUtils'],
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('any?', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'any? expects a list as first argument');
        return( (List::MoreUtils::any { Script::SXC::Runtime::apply($apply, [$_]) } @$ls) ? 1 : undef );
    },
);

CLASS->add_procedure('all?',
    inliner     => CLASS->build_inline_list_application(
        'List::MoreUtils::all', 
        surround_template => '( (%s) ? 1 : undef )', 
        required_packages => ['List::MoreUtils'],
        typehint          => 'bool',
    ),
    inline_fc   => 1,
    runtime_req => ['Validation', '+', '+List::MoreUtils'],
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('all?', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'all? expects a list as first argument');
        return( (List::MoreUtils::all { Script::SXC::Runtime::apply($apply, [$_]) } @$ls) ? 1 : undef );
    },
);

CLASS->add_procedure('none?',
    inliner     => CLASS->build_inline_list_application(
        'List::MoreUtils::none', 
        surround_template => '( (%s) ? 1 : undef )', 
        required_packages => ['List::MoreUtils'],
        typehint          => 'bool',
    ),
    inline_fc   => 1,
    runtime_req => ['Validation', '+', '+List::MoreUtils'],
    firstclass  => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('none?', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($ls, 'list', 'none? expects a list as first argument');
        return( (List::MoreUtils::none { Script::SXC::Runtime::apply($apply, [$_]) } @$ls) ? 1 : undef );
    },
);

CLASS->add_procedure('pair?',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('pair?', [@_], min => 1);
        ref and ref eq 'ARRAY' and @$_ == 2 or return undef
            for @_;
        return 1;
    },
    inline_fc   => 1,
    runtime_req => ['Validation'],
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        return CompiledValue->new(typehint => 'bool', content => sprintf
            '( not( grep { not(ref and ref eq q(ARRAY) and @$_ == 2) } (%s) ) ? 1 : undef )',
            join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
        );
    },
);

CLASS->add_procedure('zip',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('zip', [@_], min => 3);
        my ($zipper, @lists) = @_;
        Script::SXC::Runtime::Validation->runtime_type_assertion($lists[ $_ ], 'list', "zip argument @{[ $_ + 1 ]} is not a list")
            for 0 .. $#lists;
        return [ map {
            my $at = $_;
            Script::SXC::Runtime::apply($zipper, [ map { $_->[ $at ] } @lists ]);
        } 0 .. List::Util::min map { $#$_ } @lists ];
    },
    inline_fc   => 1,
    runtime_req => ['Validation', '+', '+List::Util'],
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 3);

        my ($zipper, @lists) = @$exprs;
        $compiler->add_required_package('List::Util');

        my $zipper_compiled = $zipper->compile($compiler, $env);
        my $zipper_var;
        if (     not($compiler->force_firstclass_procedures)
             and ($zipper_compiled->isa(ProcedureClass) and $zipper_compiled->inliner)
        ) {

            $zipper_var = $zipper_compiled;
        }
        else {
            $zipper_var = Variable->new_anonymous('zipper');
            $zipper_var->try_typehinting_from($zipper_compiled);
        }

        my $lists_var  = Variable->new_anonymous('zip_lists', sigil => '@');
        my $index_var  = Variable->new_anonymous('zip_index');
        return CompiledValue->new(typehint => 'list', content => sprintf
            '(do { %s my %s = (%s); [ %s ] })',
            ( ( $zipper_compiled eq $zipper_var )
              ? ''
              : sprintf('my %s = %s;',
                  $zipper_var->render,
                  $zipper_compiled->render,
                ),
            ),
            $lists_var->render,
            join(', ', map { 
                CompiledTypeCheck->new(
                    expression  => $lists[ $_ ]->compile($compiler, $env),
                    type        => 'list',
                    source_item => $symbol,
                    message     => "Argument @{[ $_ + 1 ]} to $name is not a list",
                )->render,
            } 0 .. $#lists),
            sprintf(
                'map { my %s = $_; %s } 0 .. List::Util::min(map { $#$_ } %s)',
                $index_var->render,
                CompiledApplication->new_from_uncompiled(
                    $compiler,
                    $env,
                    invocant        => $zipper_var,
                    tailcalls       => 0,
                    return_type     => 'scalar',
                    inline_invocant => not($zipper_compiled->isa(ProcedureClass) and $zipper_compiled->name eq 'apply'),
                    options         => {
                        optimize_tailcalls  => 0,
                        first_class         => $compiler->force_firstclass_procedures,
                        source              => $symbol,
                    },
                    arguments       => [
                        map {
                            CompiledValue->new(
                                content => sprintf(
                                    '(@{( %s )}[ %s ])',
                                    $lists_var->render_array_access($_),
                                    $index_var->render,
                                ),
                            );
                        } 0 .. $#lists,
                    ],
                    $symbol->source_information,
                )->render,
                $lists_var->render,
            ),
        );
    },
);

__PACKAGE__->meta->make_immutable;

1;
