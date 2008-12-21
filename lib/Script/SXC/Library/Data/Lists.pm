package Script::SXC::Library::Data::Lists;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use List::Util      qw( min max );
use List::MoreUtils qw( any all none );

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    [qw( Script::SXC::Compiled::Value               CompiledValue )],
    [qw( Script::SXC::Compiled::TypeCheck           CompiledTypeCheck )],
    [qw( Script::SXC::Compiled::Application::List   CompiledListApplication )],
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

CLASS->add_procedure('list', 
    firstclass  => sub { [@_] },
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {
        return CompiledValue->new(
            content  => sprintf('[( %s )]', join(', ', map { $_->compile($compiler, $env)->render } @$exprs)),
            typehint => 'list',
        );
    },
);

CLASS->add_procedure('head',
    firstclass  => sub ($ls, $num) {
        CLASS->runtime_arg_count_assertion('head', [@_], min => 1, max => 2);
        CLASS->runtime_type_assertion($ls, 'list', 'head expects list as first argument');
        $num-- if defined $num;
        return defined $num 
            ? [ @$ls[0 .. min($num, $#$ls)] ]
            : ( @$ls ? $ls->[0] : undef );
    },
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 2);
        my ($ls, $num) = @$exprs;

        if (@$exprs == 1) {
            return CompiledValue->new(content => sprintf(
                '( (%s)->[0] )',
                CompiledTypeCheck->new(
                    expression  => $ls->compile($compiler, $env),
                    type        => 'list',
                    source_item => $ls,
                    message     => 'first argument to head must be a list',
                )->render,
            ));
        }
        else {
            my $ls_var  = Variable->new_anonymous('head_list');
            my $num_var = Variable->new_anonymous('head_num');

            return CompiledValue->new(content => sprintf(
                'do { my %s = %s; my %s = %s; [ @{( %s )}[0 .. (@{%s} > %s ? %s : scalar(@{%s})) - 1] ] }',
                $ls_var->render,
                CompiledTypeCheck->new(
                    expression  => $ls->compile($compiler, $env),
                    type        => 'list',
                    source_item => $ls,
                    message     => 'first argument to head must be a list',
                )->render,
                $num_var->render,
                $num->compile($compiler, $env)->render,
                $ls_var->render,
                $ls_var->render,
                $num_var->render,
                $num_var->render,
                $ls_var->render,
            ), typehint => 'list');
        }
    },
);

CLASS->add_procedure('tail',
    firstclass => sub ($ls, $num) {
        CLASS->runtime_arg_count_assertion('tail', [@_], min => 1, max => 2);
        CLASS->runtime_type_assertion($ls, 'list', 'tail expects list as first argument');
        $num = $#$ls unless defined $num;
        return [ @$ls[ (@$ls - min(scalar(@$ls), $num)) .. $#$ls ] ];
    },
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 2);
        my ($ls, $num) = @$exprs;

        my $ls_var    = Variable->new_anonymous('head_list');
        my $num_var   = Variable->new_anonymous('head_num');
        my $start_var = Variable->new_anonymous('head_start_at');

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
        CLASS->runtime_arg_count_assertion('size', [@_], min => 1, max => 1);
        CLASS->runtime_type_assertion($ls, 'list', 'size requires list as argument');
        return scalar @$ls;
    },
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
        CLASS->runtime_arg_count_assertion('last-index', [@_], min => 1, max => 1);
        CLASS->runtime_type_assertion($ls, 'list', 'last-index requires list as argument');
        return $#{ $ls };
    },
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
        CLASS->runtime_arg_count_assertion('list-ref', [@_], min => 2, max => 2);
        CLASS->runtime_type_assertion($_[0], 'list', 'list-ref expects a list as first argument');
        return $_[0]->[ $_[1] ];
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
        CLASS->runtime_arg_count_assertion('append', [@_], min => 2);
        CLASS->runtime_type_assertion($_[ $_ ], 'list', "Invalid argument $_: append expects only list arguments")
            for 0 .. $#_;
        return [ map { @$_ } @_ ];
    },
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
        CLASS->runtime_arg_count_assertion('list?', [@_], min => 1);
        (ref($_) and ref($_) eq 'ARRAY') or return undef
            for @_;
        return 1;
    },
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        my $anon = Variable->new_anonymous('list_p_arg');
        return CompiledValue->new(content => sprintf(
            '( (%s) or undef )',
            join(
                ' and ',
                map {
                    sprintf 'do { my %s = %s; (ref(%s) and ref(%s) eq q(ARRAY)) }',
                        $anon->render,
                        $_->compile($compiler, $env)->render,
                        $anon->render,
                        $anon->render,
                } @$exprs,
            ),
        ), typehint => 'bool');
    },
);

CLASS->add_procedure('grep',
    inliner     => CLASS->build_inline_list_application('grep', typehint => 'list'),
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('grep', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        CLASS->runtime_type_assertion($ls, 'list', 'grep expects a list as first argument');
        return [ grep { CLASS->call_in_other_library('Script::SXC::Library::Core::Apply', 'apply', [$apply, [$_]]) } @$ls ];
    },
);

CLASS->add_procedure('map',
    inliner     => CLASS->build_inline_list_application('map', typehint => 'list'),
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('map', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        CLASS->runtime_type_assertion($ls, 'list', 'map expects a list as first argument');
        return [ map { CLASS->call_in_other_library('Script::SXC::Library::Core::Apply', 'apply', [$apply, [$_]]) } @$ls ];
    },
);

CLASS->add_procedure('count',
    inliner     => CLASS->build_inline_list_application('grep', surround_template => 'scalar(%s)', typehint => 'number'),
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('count', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        CLASS->runtime_type_assertion($ls, 'list', 'count expects a list as first argument');
        return scalar( grep { CLASS->call_in_other_library('Script::SXC::Library::Core::Apply', 'apply', [$apply, [$_]]) } @$ls );
    },
);

CLASS->add_procedure('any?',
    inliner     => CLASS->build_inline_list_application(
        'List::MoreUtils::any', 
        surround_template => '( (%s) ? 1 : undef )', 
        required_packages => ['List::MoreUtils'],
        typehint          => 'bool',
    ),
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('any?', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        CLASS->runtime_type_assertion($ls, 'list', 'any? expects a list as first argument');
        return( (any { CLASS->call_in_other_library('Script::SXC::Library::Core::Apply', 'apply', [$apply, [$_]]) } @$ls) ? 1 : undef );
    },
);

CLASS->add_procedure('all?',
    inliner     => CLASS->build_inline_list_application(
        'List::MoreUtils::all', 
        surround_template => '( (%s) ? 1 : undef )', 
        required_packages => ['List::MoreUtils'],
        typehint          => 'bool',
    ),
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('all?', [@_], min => 2, max => 2);
        my ($ls, $apply) = @_;
        CLASS->runtime_type_assertion($ls, 'list', 'all? expects a list as first argument');
        return( (all { CLASS->call_apply($apply, [$_]) } @$ls) ? 1 : undef );
    },
);

CLASS->add_procedure('pair?',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('pair?', [@_], min => 1);
        ref and ref eq 'ARRAY' and @$_ == 2 or return undef
            for @_;
        return 1;
    },
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
        CLASS->runtime_arg_count_assertion('zip', [@_], min => 3);
        my ($zipper, @lists) = @_;
        CLASS->runtime_type_assertion($lists[ $_ ], 'list', "zip argument @{[ $_ + 1 ]} is not a list")
            for 0 .. $#lists;
        my $apply = CLASS->get_apply;
        return [ map {
            my $at = $_;
            $apply->($zipper, [ map { $_->[ $at ] } @lists ]);
        } 0 .. min map { $#$_ } @lists ];
    },
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 3);

        my ($zipper, @lists) = @$exprs;
        $compiler->add_required_package('List::Util');

        my $zipper_compiled = $zipper->compile($compiler, $env);
        my $zipper_var;
        if (     not($compiler->force_firstclass_procedures)
             and ($zipper_compiled->isa(ProcedureClass) and $zipper_compiled->inliner)
#        if (not($compiler->force_firstclass_procedures)
#            and($zipper_compiled->isa(InlinerClass) 
#                or
#                and($zipper_compiled->isa(ProcedureClass) and $zipper_compiled->inliner)
#                or
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
#                CompiledApplication->new(
#                    invocant    => $zipper_var,
#                    return_type => 'scalar',
#                    arguments   => [map {
#                        CompiledValue->new(content => sprintf
#                            '(@{( %s )}[%s])',
#                            $lists_var->render_array_access($_),
#                            $index_var->render,
#                        ),
#                    } 0 .. $#lists],
#                    $symbol->source_information,
#                )->render,
                $lists_var->render,
            ),
        );
    },
);

1;
