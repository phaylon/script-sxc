package Script::SXC::Test::Library::Core::Syntax;
use 5.010;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump   qw( pp );
use Scalar::Util qw( refaddr );

use constant SyntaxRulesClass    => 'Script::SXC::Compiled::SyntaxRules';
use constant PatternClass        => join('::', SyntaxRulesClass, 'Pattern');
use constant TransformerClass    => join('::', SyntaxRulesClass, 'Transformer');
use constant ContextClass        => join('::', SyntaxRulesClass, 'Context');
use constant LibraryItemClass    => join('::', TransformerClass, 'LibraryItem');
use constant InsertCapturedClass => join('::', TransformerClass, 'InsertCaptured');
use constant GeneratedClass      => join('::', TransformerClass, 'Generated');
use constant RuleClass           => join('::', SyntaxRulesClass, 'Rule');
use constant ListPattern         => join('::', SyntaxRulesClass, 'Pattern::List');
use constant SymbolPattern       => join('::', SyntaxRulesClass, 'Pattern::Symbol');
use constant LiteralPattern      => join('::', SyntaxRulesClass, 'Pattern::Symbol::Literal');
use constant CapturePattern      => join('::', SyntaxRulesClass, 'Pattern::Symbol::Capture');
use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant ListClass           => 'Script::SXC::Tree::List';
use constant NumberClass         => 'Script::SXC::Tree::Number';
use constant NumberLibrary       => 'Script::SXC::Library::Data::Numbers';
use constant LetLibrary          => 'Script::SXC::Library::Core::Let';
use constant ProcedureClass      => 'Script::SXC::Library::Item::Procedure';

sub T100_syntax_rules_api: Tests {
    my $self = shift;

    {   my $body   = '(syntax-rules (to) ((add (x to y)) (+ x y)) ((add x) (let ((y 3)) (+ x y))))';
        my $simple;
        lives_ok { $simple = $self->sx_compile_tree($body) } 'syntax-rules compiles';
        is scalar(@{ $simple->expressions }), 1, 'syntax-rules compiled to single transformer item';

        isa_ok +(my $sr = $simple->expressions->[0]), SyntaxRulesClass;
        is $sr->literal_count, 1, 'transformer contains one literal';
        is $sr->rule_count, 2, 'transformer contains two rules';

        my ($rule1, $rule2) = @{ $sr->rules };
        my $literal         = $sr->literals->[0];
        isa_ok $literal, SymbolClass;
        is $literal->value, 'to', 'literal symbol has correct value';
        isa_ok $_, RuleClass for $rule1, $rule2;

        {   say '# first rule pattern';
            my $pattern = $rule1->pattern;
            isa_ok $pattern, PatternClass;
            is $pattern->item_count, 1, 'pattern for first rule contains single item';

            my $list = $pattern->get_item(0);
            isa_ok $list, ListPattern;
            is $list->item_count, 3, 'list item contains three subitems';

            {   my ($x, $to, $y) = @{ $list->items };
                isa_ok $x,  CapturePattern;
                isa_ok $y,  CapturePattern;
                isa_ok $to, LiteralPattern;
                is $x->value,  'x',  'first capture pattern has correct value';
                is $y->value,  'y',  'second capture pattern has correct value';
                is $to->value, 'to', 'literal pattern has correct value';
            }
        }

        {   say '# first rule transformer';
            my $trans = $rule1->transformer;
            isa_ok $trans, TransformerClass;
            
            my $template = $trans->template;
            isa_ok $template, ListClass;
            is $template->content_count, 3, 'template for first rule is list with three elements';
            #exit;

            my ($add, $x, $y) = @{ $template->contents };
            isa_ok $add, LibraryItemClass;
            is $add->library, NumberLibrary, 'library procedure is bound to its library';
            is $add->name, '+', 'procedure has correct name';
            isa_ok $x, InsertCapturedClass;
            is $x->name, 'x', 'first capture has correct name';
            isa_ok $y, InsertCapturedClass;
            is $y->name, 'y', 'second capture has correct name';
        }

        {   say '# second rule pattern';
            my $pattern = $rule2->pattern;
            isa_ok $pattern, PatternClass;
            is $pattern->item_count, 1, 'pattern for second rule contains single item';

            my $x = $pattern->get_item(0);
            isa_ok $x, CapturePattern;
            is $x->value, 'x', 'capture pattern has correct value';
        }

        {   say '# second rule transformer';
            my $trans = $rule2->transformer;
            isa_ok $trans, TransformerClass;
            
            my $template = $trans->template;
            isa_ok $template, ListClass;
            is $template->content_count, 3, 'template for second rule is list with three elements';

            my ($let_sym, $let_vars, $let_expr) = @{ $template->contents };

            isa_ok $let_sym, LibraryItemClass;
            is $let_sym->library, LetLibrary, 'let element is bound to its library';
            is $let_sym->name, 'let', 'let element has correct name';

            isa_ok $let_vars, ListClass;
            is $let_vars->content_count, 1, 'let contains single definition';
            isa_ok $let_vars->get_content_item(0), ListClass;
            is $let_vars->get_content_item(0)->content_count, 2, 'definition contains two expressions';

            my ($var_sym, $var_expr) = @{ $let_vars->get_content_item(0)->contents };
            isa_ok $var_sym, GeneratedClass;
            is $var_sym->value, 'y', 'generated symbol has correct value';
            isa_ok $var_expr, NumberClass;
            is $var_expr->value, '3', 'constant number has correct value';

            isa_ok $let_expr, ListClass;
            is $let_expr->content_count, 3, 'let expression is list with three elements';

            my ($add, $x, $y) = @{ $let_expr->contents };
            isa_ok $add, LibraryItemClass;
            is $add->library, NumberLibrary, 'library procedure is bound to its library';
            is $add->name, '+', 'procedure has correct name';
            isa_ok $x, InsertCapturedClass;
            is $x->name, 'x', 'capture has correct name';
            isa_ok $y, GeneratedClass;
            is $y->value, 'y', 'generated symbol has correct name';
            is refaddr($y), refaddr($var_sym), 'generated symbols in let variables and let expression are the same object';
        }

        {   say '# transforming first syntax-rule';
            my $ls = $self->sx_build_stream('(3 to 5)')->contents->[0];

            my $ctx = $sr->find_matching_rule([$ls]);
            isa_ok $ctx, ContextClass, 'match result is context object';
            isa_ok $ctx->rule, RuleClass;
            ok $ctx->has_capture_store_for('x'), 'captures contain first capture name';
            ok $ctx->has_capture_store_for('y'), 'captures contain second capture name';
            isa_ok $ctx->get_capture_store_for('x'), NumberClass;
            isa_ok $ctx->get_capture_store_for('y'), NumberClass;

            my $tree = $ctx->build_tree($self->compiler, $self->compiler->top_environment);
            isa_ok $tree, ListClass;
#            exit;
            is $tree->content_count, 3, 'transformed expression has correct number of items';

            my ($add, $x, $y) = @{ $tree->contents };
            isa_ok $add, SymbolClass;
            isa_ok $x,   NumberClass;
            isa_ok $y,   NumberClass;
            is $add->value, '+', 'transformed expression has correct procedure';
            is $x->value, 3, 'first constant has correct value';
            is $y->value, 5, 'second constant has correct value';
        }

        #exit;
    }
}

sub T200_syntax_rules_usage: Tests {
    my $self = shift;

    my $PRE = q#
        (define-syntax calc
          (syntax-rules (sum of and half square)
            [(calc sum of <x> and <y>)
             (+ <x> <y>)]
            [(calc sum of <x> and <y> and <z>)
             (+ <x> <y> <z>)]
            [(calc half of <x>)
             (/ <x> 2)]
            [(calc square of <x>)
             (* <x> <x>)]))
    #;
    
    is $self->run($PRE, '(calc sum of 7 and 9)'), 16, 'first rule transforms correctly';
    is $self->run($PRE, '(calc sum of 7 and 9 and 10)'), 26, 'second rule transforms correctly';
    is $self->run($PRE, '(calc half of 10)'), 5, 'third rule transforms correctly';
    is $self->run($PRE, '(calc square of 7)'), 49, 'fourth rule transforms correctly';

    throws_ok { $self->run($PRE, '(calc gajillions of numbers)') } 'Script::SXC::Exception::ParseError',
        'no matching rule leads to parse error being thrown';
    like $@, qr/rule/i, 'error message contains "rule"';
}

sub T201_syntax_rules_nested: Tests {
    my $self = shift;

    my $PRE = q#
        (define-syntax add
          (syntax-rules (to)
            ((add <x> to <y>)
             (+ <x> <y>))))
    #;
    
    is $self->run($PRE, '(add (add 2 to 3) to (add 4 to 5))'), 14, 'nested syntax-rules inlinings do not collide';
}

sub T202_syntax_rules_errors: Tests {
    my $self = shift;

    {   my $PRE = q#
            (define-syntax fetch
              (syntax-rules (from)
                ((fetch f from h)
                 ((lambda (data)
                    (hash-ref data f))
                  h))))
        #;
        
        throws_ok { $self->run($PRE, '(fetch :foo from 23)') } 'Script::SXC::Exception';
        like $@, qr/hash/i, 'error message is the expected one';
    }

    throws_ok { $self->run('(define-syntax "foo" (syntax-rules () ((foo) 23)))') } 'Script::SXC::Exception::ParseError',
        'non-symbol as syntax container for define-syntax throws parse error';
    like $@, qr/define-syntax/, 'error message contains "define-syntax"';
    like $@, qr/symbol/i, 'error message contains "symbol"';

    throws_ok { $self->run('(define-syntax 1 2 3)') } 'Script::SXC::Exception',
        'more than two arguments to define-syntax throws exception';
    like $@, qr/define-syntax/, 'error message contains "define-syntax"';
    like $@, qr/too many/i, 'error message contains "too many"';

    throws_ok { $self->run('(define-syntax foo)') } 'Script::SXC::Exception',
        'single argument to define-syntax throws exception';
    like $@, qr/define-syntax/, 'error message contains "define-syntax"';
    like $@, qr/missing/i, 'error message contains "missing"';

    throws_ok { $self->run('(define-syntax foo 23)') } 'Script::SXC::Exception::ParseError',
        'non-transformer as second argument to define-syntax throws parse error';
    like $@, qr/define-syntax/, 'error message contains "define-syntax"';
    like $@, qr/compiled syntax transformer/i, 'error message contains "compiled syntax transformer"';

    my $FOO = sub { $self->run(sprintf '(define-syntax foo (syntax-rules (lit1 lit2) %s)) %s', shift, join ' ', @_) };

    throws_ok { $FOO->('((foo 23 ...) 23)') } 'Script::SXC::Exception::ParseError',
        'trying to greedify a number throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/unable to greedify/i, 'error message contains "unable to greedify"';
    like $@, qr/number/i, 'error message contains "number"';

    throws_ok { $FOO->('((foo lit1 ...) 23)') } 'Script::SXC::Exception::ParseError',
        'trying to greedify a literal throws a parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/unable to greedify/i, 'error message contains "unable to greedify"';
    like $@, qr/literal/i, 'error message contains "literal"';
    
    throws_ok { $FOO->('((foo ...) 23)') } 'Script::SXC::Exception::ParseError',
        'ellipsis without previous pattern throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/ellipsis/i, 'error message contains "ellipsis"';

    throws_ok { $FOO->('((foo <x> ... <y>) 23)') } 'Script::SXC::Exception::ParseError',
        'pattern after ellipsis throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/ellipsis/i, 'error message contains "ellipsis"';
    like $@, qr/last/i, 'error message contains "last"';

    throws_ok { $FOO->('((foo <x>) (+ <x> ...))') } 'Script::SXC::Exception::ParseError',
        'ellipsis in template but not in transformer throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/level/i, 'error message contains "level"';

    throws_ok { $FOO->('((foo <x> ...) (+ (* <x> ...) ...))') } 'Script::SXC::Exception::ParseError',
        'more iteration than greedy levels throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/level/i, 'error message contains "level"';

    throws_ok { $FOO->('((foo <x> ...) (+ 17 ...))') } 'Script::SXC::Exception::ParseError',
        'trying to iterate over a constant in template throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/placement/i, 'error message contains "placement"';
    like $@, qr/ellipsis/i, 'error message contains "ellipsis"';
    like $@, qr/number/i, 'error message contains constant type';

    throws_ok { $FOO->('((foo <x> ...) (+ <qux> ...))') } 'Script::SXC::Exception::ParseError',
        'trying to iterate over a generated symbol in template throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/placement/i, 'error message contains "placement"';
    like $@, qr/ellipsis/i, 'error message contains "ellipsis"';
    like $@, qr/symbol/i, 'error message contains symbol type';

    throws_ok { $FOO->('((foo <x> <x>) 23)') } 'Script::SXC::Exception::ParseError',
        'double usage of same capture symbol in pattern throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/<x>/, 'error message contains capture symbol';
    like $@, qr/capture/i, 'error message contains "capture"';
    like $@, qr/once/i, 'error message contains "once"';

    throws_ok { $FOO->('((foo <x>) (doesnotreallyexist <x>))', '(foo 23)') } 'Script::SXC::Exception::UnboundVar',
        'generated symbol that was not used in definition first throws parse error';
    like $@->name, qr/doesnotreallyexist/, 'variable name contains original symbol name';
    like $@->name, qr/^#gensym~.+#$/, 'variable name is in correct gensym format';

    throws_ok { $FOO->('(() 23)') } 'Script::SXC::Exception::ParseError',
        'pattern without contents throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/pattern/i, 'error message contains "pattern"';

    throws_ok { $FOO->('(foo 23)') } 'Script::SXC::Exception::ParseError',
        'pattern with non-list as rule throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/pattern/i, 'error message contains "pattern"';
    like $@, qr/list/i, 'error message contains "list"';

    throws_ok { $FOO->('((foo) 2 3)') } 'Script::SXC::Exception::ParseError',
        'rule with more than two expressions throws parse error';
    like $@, qr/syntax-rules/, 'error message contains "syntax-rules"';
    like $@, qr/pattern/i, 'error message contains "pattern"';
    like $@, qr/two/i, 'error message contains "two"';





#    exit;
}

sub T203_syntax_rules_gensym: Tests {
    my $self = shift;

    my $PRE = q#
        (define-syntax foo
          (syntax-rules ()
            [(foo <expr>)
             (let [(val <expr>)]
               (* val val))]))
    #;

    is $self->run($PRE, '(let [(n 3)] (foo (apply! n ++)))'), 16, 'generated symbols allow value definition';
}

sub T204_syntax_rules_hashes: Tests {
    my $self = shift;

    my $PRE = q#
        (define-syntax my-map-do
          (syntax-rules ()
            [(my-map-do (<var> <keyer> <ls>) <expr>)
             (map <ls> (lambda (<var>) { (<keyer> <var>) <expr> }))]))
    #;
    
    is_deeply $self->run($PRE, '(my-map-do (foo ++ (list 3 4 5)) { result: foo })'),
        [{ 4 => { result => 3 } }, { 5 => { result => 4 } }, { 6 => { result => 5 } }],
        'hash construction in captured and template build correctly';

    my $PRE2 = q#
        (define-syntax extract-foo
          (syntax-rules ()
            ((_ (foo)) (list "list" foo))
            ((_ {foo}) (list "hash" foo))))
    #;
    is_deeply $self->run($PRE2, '(list (extract-foo (23)) (extract-foo {42}))'),
        [[list => 23], [hash => 42]],
        'syntax-rules successfully distinguishes between lists and hashes in templates';
}

sub T205_syntax_rules_constants: Tests {
    my $self = shift;

    my $PRE = q#
        (define-syntax foo
          (syntax-rules ()
            ((foo "1") "string-1")
            ((foo "2") "string-2")
            ((foo 1) "int-1")
            ((foo 2) "int-2")))
    #;
    is $self->run($PRE, '(foo "1")'), 'string-1', 'first string dispatches to correct rule';
    is $self->run($PRE, '(foo "2")'), 'string-2', 'second string dispatches to correct rule';
    is $self->run($PRE, '(foo 1)'), 'int-1', 'first integer dispatches to correct rule';
    is $self->run($PRE, '(foo 2)'), 'int-2', 'second integer dispatches to correct rule';
}

sub T206_syntax_rules_ellipsis: Tests {
    my $self = shift;

    {   my $PRE = q#
            (define-syntax foo
              (syntax-rules ()
                ((foo <x> <y> ...)
                 (+ <x> (+ <y> 1) ...))))
        #;
        is $self->run($PRE, '(foo 3 4 5 6)'), (3 + ((4 + 1) + (5 + 1) + (6 + 1))),
            'single level ellipsis captures and builds correctly';
    }

    {   my $PRE = q#
            (define-syntax foo
              (syntax-rules ()
                ((foo (<name> <item> ...) ...)
                 (merge {} {} { <name> (+ (+ <item> 1) ...) } ...))))
        #;
        is_deeply $self->run($PRE, '(foo (x: 2 3 4) (y: 3 4 5))'),
            { x => 12, y => 15 },
            'multi level ellipsis captures and builds correctly';
        is_deeply $self->run($PRE, '(list (foo (x:)) (foo))'),
            [{ x => 0 }, {}],
            'multi level ellipsis can iterate on zero items';
    }

    {   my $PRE = q#
            (define-syntax foo
              (syntax-rules ()
                ((foo (<name> <init> <apply> <arg> ...) ...)
                 (let ((<name> <init>) ...)
                   (list (<apply> <name> <arg> ...)
                         ...)))))
        #;
        is_deeply $self->run($PRE, '(foo (bar 23 list 2 3 4) (baz 17 ++))'),
            [[23, 2, 3, 4], 18],
            'multi level ellipsis can iterate multiple times';
    }
}

sub T207_syntax_rules_recursion: Tests {
    my $self = shift;

    my $PRE = q#
        (define-syntax foo
          (syntax-rules ()
            ((foo a b c d)
             (+ a b c d))
            ((foo a b c)
             (foo a b c (++ c)))
            ((foo a b)
             (foo a b (++ b)))
            ((foo a)
             (foo a (++ a)))
            ((foo)
             (foo 1))))
    #;

    is_deeply $self->run($PRE, '(foo 1 2 3 4)'), 10, 'non recursive use of recursive syntax templates';
    is_deeply $self->run($PRE, '(foo 1 2 3)'), 10, 'single level recursion';
    is_deeply $self->run($PRE, '(foo 1 2)'), 10, 'two level recursion';
    is_deeply $self->run($PRE, '(foo 1)'), 10, 'three level recursion';
    is_deeply $self->run($PRE, '(foo)'), 10, 'four level recursion without any arguments';
}

1;
