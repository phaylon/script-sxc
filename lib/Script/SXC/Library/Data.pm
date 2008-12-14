package Script::SXC::Library::Data;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use CLASS;
use List::Util qw( min max );
use Scalar::Util qw( blessed refaddr );

use aliased 'Script::SXC::Compiled::Value',         'CompiledValue';
use aliased 'Script::SXC::Compiled::TypeCheck',     'CompiledTypeCheck';
use aliased 'Script::SXC::Compiled::TypeSwitch',    'CompiledTypeSwitch';
use aliased 'Script::SXC::Compiler::Environment::Variable';
use aliased 'Script::SXC::Exception::ArgumentError';

use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

#
#   lists
#

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

#   list-ref ideas:
#
#       (define foo (list 1 2 3))
#
#       (foo 1)                     => 2
#       (set! (foo 1) 23)           => 23 (1 23 3)
#       (set! (foo (+ 1 1)) 42)     => 42 (1 23 42)
#
#   access:
#       
#       (define foo (list 1 (hash :foo (list 2 3) :bar (list (hash :x 2) (hash :y 3)))))
#
#       ((foo 2) :foo)              => (2 3)
#       (foo 1 :bar 0 :x)           => 2
#       (set! (foo 1 :foo 2) 4)     => 4 (list 1 (hash :foo (list 2 3 4) :bar ...))
#

#
#   hashes
#

CLASS->add_procedure('hash', 
    firstclass => sub {
        ArgumentError->throw_to_caller(
            type    => 'invalid_argument_list',
            message => "hash constructor expects even size list of key/value pairs",
        ) if @_ % 2;
        return +{ @_ };
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        (@$exprs ? $exprs->[-1] : $symbol)->throw_parse_error(
            invalid_argument_list => "hash constructor expects even sized list of key/value pairs",
        ) if @$exprs % 2;
        return CompiledValue->new(
            content  => sprintf('+{( %s )}', join(', ', map { $_->compile($compiler, $env, to_string => 1)->render } @$exprs)),
            typehint => 'hash',
        );
    },
);

CLASS->add_procedure('values',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('values', [@_], min => 1, max => 1);
        CLASS->runtime_type_assertion($_[0], 'hash', 'values expects a hash as argument');
        return [ values %{ $_[0] } ];
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf(
            '[ values %%{ %s } ]',
            CompiledTypeCheck->new(
                expression  => $exprs->[0]->compile($compiler, $env),
                type        => 'hash',
                source_item => $exprs->[0],
                message     => "$name expects a hash as argument",
            )->render,
        ), typehint => 'list');
    },
);

CLASS->add_procedure('keys',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('keys', [@_], min => 1, max => 1);
        CLASS->runtime_type_assertion($_[0], 'hash', 'keys expects a hash as argument');
        return [ keys %{ $_[0] } ];
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        return CompiledValue->new(content => sprintf(
            '[ keys %%{ %s } ]',
            CompiledTypeCheck->new(
                expression  => $exprs->[0]->compile($compiler, $env),
                type        => 'hash',
                source_item => $exprs->[0],
                message     => "$name expects a hash as argument",
            )->render,
        ), typehint => 'list');
    },
);

CLASS->add_procedure('hash-ref',
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('hash-ref', [@_], min => 2, max => 2);
        CLASS->runtime_type_assertion($_[0], 'hash', 'hash-ref expects a hash as first argument');
        return $_[0]->{ $_[1] };
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs, :$name, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);

        return CompiledValue->new(
            content => sprintf('( (%s)->{%s} )', 
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'hash',
                    source_item => $exprs->[0],
                    message     => 'first argument to hash-ref must be a hash',
                )->render,
                $exprs->[1]->compile($compiler, $env, to_string => 1)->render,
            ),
        );
    },
);

CLASS->add_procedure('merge',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('merge', [@_], min => 2);
        CLASS->runtime_type_assertion($_[ $_ ], 'hash', "Invalid argument $_: merge expects only hash arguments")
            for 0 .. $#_;
        return +{ map { (%$_) } @_ };
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        return CompiledValue->new(content => sprintf(
            '(+{( %s )})',
            join(', ', map {
                sprintf '(%%{( %s )})', CompiledTypeCheck->new(
                    expression  => $exprs->[ $_ ]->compile($compiler, $env),
                    type        => 'hash',
                    source_item => $exprs->[ $_ ],
                    message     => "Invalid argument $_: $name expects only hash arguments",
                )->render,
            } 0 .. $#$exprs),
        ), typehint => 'hash');
    },
);

CLASS->add_procedure('hash?',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('hash?', [@_], min => 1);
        (ref($_) and ref($_) eq 'HASH') or return undef
            for @_;
        return 1;
    },
    inliner => method (:$compiler!, :$env!, :$exprs!, :$name!, :$error_cb!, :$symbol!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        my $anon = Variable->new_anonymous('hash_p_arg');
        return CompiledValue->new(content => sprintf(
            '( (%s) or undef )',
            join(
                ' and ',
                map {
                    sprintf 'do { my %s = %s; (ref(%s) and ref(%s) eq q(HASH)) }',
                        $anon->render,
                        $_->compile($compiler, $env)->render,
                        $anon->render,
                        $anon->render,
                } @$exprs,
            ),
        ), typehint => 'bool');
    },
);

#
#   strings
#

CLASS->add_procedure('string',
    firstclass => sub { join '', @_ },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, Str :$name!, :$error_cb!, Object :$symbol!) {
        return CompiledValue->new(content => sprintf(
            'join("", %s)',
            join(', ', map { $_->compile($compiler, $env, to_string => 1)->render } @$exprs),
        ), typehint => 'string')
    },
);

#
#   general
#

CLASS->add_procedure('empty?',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('empty?', [@_], min => 1);
        for my $arg_x (0 .. $#_) {
            my $arg = $_[ $arg_x ];
            given (ref $arg) {
                when ('ARRAY') { return undef if @$arg }
                when ('HASH')  { return undef if keys %$arg }
                when ('')      { return undef if length $arg }
                default {
                    ArgumentError->throw_to_caller(
                        type    => 'invalid_argument_type',
                        message => "Invalid argument type: Argument $arg_x to empty? is neither a list, hash nor a string",
                    );
                }
            }
        }
        return 1;
    },
    inliner => method (:$compiler, :$env, :$exprs, :$error_cb, :$name) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        my $arg_x = 0;
        return CompiledValue->new(content => sprintf '(%s)', join ' and ', map {
            CompiledTypeSwitch->new(
                expression  => $_->compile($compiler, $env),
                source_item => $_,
                typemap     => {
                    'string'    => '( length( %s )         ? undef : 1)',
                    'list'      => '( scalar(@{ %s })      ? undef : 1)',
                    'hash'      => '( scalar(keys %{ %s }) ? undef : 1)',
                },
                message     => "Invalid argument type: Argument @{[ $arg_x++ ]} is neither string, hash nor list",
                error_type  => 'invalid_argument_type',
                error_class => ArgumentError,
            )->render;
        } @$exprs);
    },
);

CLASS->add_procedure('reverse',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('reverse', [@_], min => 1, max => 1);
        my $item = shift;
        given (ref $item) {
            when ('ARRAY') { return  [ reverse @$item ] }
            when ('HASH')  { return +{ reverse %$item } }
            when ('')      { return    reverse $item    }
            default {
                ArgumentError->throw_to_caller(
                    type    => 'invalid_argument_type',
                    message => "Invalid argument type: Argument to reverse must be a list, hash or a string",
                );
            }
        }
    },
    inliner => method (:$compiler!, :$env!, :$name!, :$exprs!, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        my $expr = $exprs->[0];
        return CompiledTypeSwitch->new(
            expression  => $expr->compile($compiler, $env),
            source_item => $expr,
            typemap     => {
                'string'    => 'reverse(%s)',
                'list'      => '[ reverse @%s ]',
                'hash'      => '(+{( reverse %%s )})',
            },
            message     => "Invalid argument type: Argument to $name must be a list, hash or a string",
            error_type  => 'invalid_argument_type',
            error_class => ArgumentError,
        );
    },
);

CLASS->add_procedure('exists?',
    firstclass  => sub {
        CLASS->runtime_arg_count_assertion('exists?', [@_], min => 2);
        my ($item, @keys) = @_;
        given (ref $item) {
            when ('ARRAY') { exists $item->[ $_ ] or return undef for @keys }
            when ('HASH')  { exists $item->{ $_ } or return undef for @keys }
            default {
                ArgumentError->throw_to_caller(
                    type    => 'invalid_argument_type',
                    message => "Invalid argument type: First argument to exists? must be a list or hash",
                );
            }
        }
        return 1;
    },
    inliner => method (:$compiler!, :$env!, :$name!, :$exprs, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        my ($container, @keys) = @$exprs;
        my $keylist = join ', ', map { $_->compile($compiler, $env, to_string => 1)->render } @keys;
        return CompiledTypeSwitch->new(
            expression  => $container->compile($compiler, $env),
            source_item => $container,
            typemap     => {
                'list'      => '( (grep { not exists %s->[ $_ ] } ' . $keylist . ') ? 0 : 1 )',
                'hash'      => '( (grep { not exists %s->{ $_ } } ' . $keylist . ') ? 0 : 1 )',
            },
            message     => "Invalid argument type: Argument to $name must be a list or hash",
            error_type  => 'invalid_argument_type',
            error_class => ArgumentError,
        );
    },
);

CLASS->add_procedure('copy',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('copy', [@_], min => 1, max => 1);
        my $item = shift;
        given (ref $item) {
            when ('ARRAY')                          { return  [ @$item ] }
            when ('HASH')                           { return +{ %$item } }
            when ('')                               { return     $item   }
            when ('Script::SXC::Runtime::Symbol')   { return ref($item)->new(value => $item->value) }
            when ('Script::SXC::Runtime::Keyword')  { return     $item   }
            default {
                ArgumentError->throw_to_caller(
                    type    => 'invalid_argument_type',
                    message => "Invalid argument type: Unable to make a copy of '$item'. Need either a list, hash, string, symbol or keyword",
                );
            }
        }
    },
    inliner => method (:$compiler!, :$env!, :$name!, :$exprs!, :$error_cb!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        my $item = $exprs->[0];
        return CompiledTypeSwitch->new(
            expression  => $item->compile($compiler, $env),
            source_item => $item,
            typemap     => {
                'list'      => '[ @{ (%s) } ]',
                'hash'      => '(+{( %{ (%s) } )})',
                'string'    => '%s',
                'symbol'    => 'ref(%s)->new(value => (%s)->value)',
                'keyword'   => '%s',
            },
            message     => 'Invalid argument type: Unable to make a copy of \'%s\' Need either list, hash, string, symbol or keyword',
            error_type  => 'invalid_argument_type',
            error_class => ArgumentError,
        );
    },
);

CLASS->add_procedure('~~',
    firstclass => sub {
        CLASS->runtime_arg_count_assertion('~~', [@_], min => 2, max => 2);
        return( $_[0] ~~ $_[1] ? 1 : undef );
    },
    inliner => method (:$compiler!, :$env!, :$name!, :$exprs!, :$error_cb!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
        return CompiledValue->new(content => sprintf 
            '( (%s ~~ %s) ? 1 : undef )',
            map { $_->compile($compiler, $env) } @$exprs,
        );
    },
);

# 
# TODO missing
#
#   (is? foo! ...)       ; array(same contents), hash(same keys/values), object(same id), scalar(equal)
#   (~~ foo! bar!)
#   (delete! hs|ls! at! ...)
#   (grep ls|hs! proc?)
#   (any? ls|hs! proc!)
#   (all? ls|hs! proc!)
#   (none? ls|hs! proc!)
#   (one? ls|hs! proc!)
#   (defined? x)
#
#   (! foo 23)          ; (not (foo 23))
#
#   (list->hash h!)
#   (hash->list h!)
#   (pair? p! ...)
#
#   (each hs! proc!)
#   
#   (map ls! proc!)
#   (head ls! proc|num?)
#   (tail ls! proc|num?)
#   (splice ls! offset|startproc! length|endproc!)
#   (first-index ls! proc?)
#   (last-index ls! proc?)
#   (gather ... (take n! ...) ...)
#   (push! ls! item! ...)
#   (pop! ls!)
#   (unshift! ls! item! ...)
#   (shift! ls!)
#   (sort ls! proc!)
#   (flatten '((2 3) (3 4))! ...)           ; => (2 3 3 4)
#   (reduce ls! proc!)
#
#   (string? s! ...)
#   (length str!)
#   (join ls! str?)
#   (index str! what!)
#   (rindex str! what!)
#   (substr str! offset! length?)
#   (chomp str!)
#   (lc str!)
#   (uc str!)
#   (lc-first str!)
#   (uc-first str!)
#   (sprintf "[%02d:%02d:%02d]" hour minute second)
#   (eq? str! str! ...)
#   (ne? str! str!)
#   (lt? str! str! ...)
#   (gt? str! str! ...)
#   (le? str! str! ...)
#   (ge? str! str! ...)
#
#   (+ num? ...)
#   (- num? ...)
#   (* num? ...)
#   (/ num! num!)
#   (mod num! num!)
#   (++ num!)
#   (-- num!)
#   (== num! num! ...)
#   (!= num! num!)
#   (< num! num! ...)
#   (> num! num! ...)
#   (<= num! num! ...)
#   (>= num! num! ...)
#
#   (code? c! ...)
#   (curry foo 2 3)         ; => (lambda args (apply foo 2 3 args))
#   (rcurry foo 2 3)        ; => (lambda args (apply foo (append args (list 2 3))))
#
#   (ref? x! ...)
#   (reftype foo!)
#   (refaddr foo!)
#

1;
