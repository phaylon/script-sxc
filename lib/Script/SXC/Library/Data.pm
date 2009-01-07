package Script::SXC::Library::Data;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use CLASS;
use List::Util qw( min max );
use Scalar::Util qw( blessed refaddr );

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value',         'CompiledValue'     ],
    ['Script::SXC::Compiled::TypeCheck',     'CompiledTypeCheck' ],
    ['Script::SXC::Compiled::TypeSwitch',    'CompiledTypeSwitch'],
    'Script::SXC::Compiler::Environment::Variable',
    'Script::SXC::Exception::ArgumentError';

use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_delegated_items({

    'Script::SXC::Library::Data::Lists'     
        => [qw( list list? head tail size last-index list-ref append map grep count any? all? none? pair? zip )],

    'Script::SXC::Library::Data::Hashes'    
        => [qw( hash hash? keys values hash-ref merge )],

    'Script::SXC::Library::Data::Strings'   
        => [qw( string string? lt? gt? le? ge? eq? ne? join )],

    'Script::SXC::Library::Data::Numbers'   
        => [qw( + - * -- ++ / < > <= >= == != = abs mod even? odd? min max )],

    'Script::SXC::Library::Data::Code'
        => [qw( code? curry rcurry )],

    'Script::SXC::Library::Data::Regex'
        => [qw( match match-all named-match named-match-full regex? )],
});

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
#
#   also:
#
#       (<-- (λ (n) (* n 2))
#            abs
#            (let ((x 1))
#              (λ () (if (< x 10)
#                        (set! x (++ x))
#                        #f))))
#

#
#   general
#

CLASS->add_procedure('false?',
    firstclass => sub {
        return 1 unless @_;
        not $_ or return undef for @_;
        return 1;
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        # TODO: single value optimization
        my $values = Variable->new_anonymous('false_test_values', sigil => '@');
        return CompiledValue->new(content => sprintf 
            '(do { my %s = (%s); ( not(grep { $_ } %s) ? 1 : undef ) })', 
            $values->render,
            join(', ', map { $_->compile($compiler, $env)->render } @$exprs),
            $values->render,
        );
    },
);

CLASS->add_procedure('true?',
    firstclass => sub {
        return undef unless @_;
        $_ or return undef for @_;
        return $_[-1];
    },
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        # TODO: single value optimization
        my $values = Variable->new_anonymous('true_test_values', sigil => '@');
        return CompiledValue->new(content => sprintf 
            '(do { my %s = (%s); ( not(grep { not($_) } %s) ? %s : undef ) })', 
            $values->render,
            join(', ', map { $_->compile($compiler, $env)->render } @$exprs),
            $values->render,
            $values->render_array_access(-1),
        );
    },
);

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

# 
# TODO missing
#
#   (is? foo! ...)       ; array(same contents), hash(same keys/values), object(same id), scalar(equal)
#   (~~ foo! bar!)
#   (delete! hs|ls! at! ...)
#   (without hash|list! ...)            ; (without { x: 23 y: 17 } :x)  => { y: 17 }
#                                       ; (without '(1 2 3 4) 0 2)      => '(2 4)
#   (one? ls|hs! proc!)
#   (defined? x)
#
#   (! foo 23)          ; (not (foo 23))
#
#   (list->hash h!)
#   (hash->list h!)
#
#   (each hs! proc!)
#
#   (cmp str! str!)
#   (<=> num! num!)
#   
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
