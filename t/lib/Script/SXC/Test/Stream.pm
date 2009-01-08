package Script::SXC::Test::Reader;
use strict;
use parent 'Script::SXC::Test';
use Method::Signatures;
use self;

use CLASS;
use Test::Most;
use aliased 'Script::SXC::Reader',  'ReaderClass';
use aliased 'Script::SXC::Tree',    'TreeClass';
use Data::Dump qw( dump );

use Script::SXC::Test::Util 
    qw( assert_ok list_ok symbol_ok builtin_ok quote_ok string_ok number_ok );

CLASS->mk_accessors(qw( reader ));

sub setup_reader: Test(startup) {
    self->reader(ReaderClass->new);
}

sub transform {
    my ($body) = args;
    explain "transforming: '$body'";
    self->reader->build_stream(\$body)->transform;
}

sub whitespaces: Tests {

    {   # some simple whitespaces
        explain 'whitespace tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform("  \n\t\n  ");
        isa_ok $tree, TreeClass;
        is $tree->content_count, 0, 'whitespace becomes empty tree';
    }
}

sub symbols: Tests {

    {   # single symbol
        explain 'symbol tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('foo');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'correct number of items in tree';
        isa_ok my $symbol = $tree->get_content_item(0), 'Script::SXC::Tree::Symbol';
        is $symbol->value, 'foo', 'symbol in tree has correct value';
        is $symbol->line_number, 1, 'symbol in tree contains correct line number';
        is $symbol->source_description, '(scalar)', 'symbol in tree contains source description';
    }

    {   # multiple symbols
        explain 'multi symbol tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform("foo\nbar\nbaz");
        isa_ok $tree, TreeClass;
        is $tree->content_count, 3, 'tree contains three items';

        my @expected = qw( foo bar baz );
        for my $x (0 .. 2) {
            my $item = $tree->get_content_item($x);
            isa_ok $item, 'Script::SXC::Tree::Symbol';
            is $item->value, $expected[ $x ], "symbol $x has correct value";
            is $item->source_description, '(scalar)', "symbol $x has correct source description";
            is $item->line_number, $x + 1, "symbol $x has correct line number";
        }
    }

    {   # dot symbols
        explain 'dot tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('.');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in dot tree';
        my $dot = $tree->get_content_item(0);
        isa_ok $dot, 'Script::SXC::Tree::Symbol';
        isa_ok $dot, 'Script::SXC::Tree::Dot';
        is $dot->value, '.', 'dot value correct';
    }
}

sub regexes: Tests {

    {   # simple regex
        explain 'simple regex: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('/foo/');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in simple regex tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Regex';
        is $item->value, qr/(?:foo)/x, 'regex in tree has correct value';
    }

    {   # complex regex
        explain 'complex regex: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('/\Afoo$bar%baz@qux (\@.\%.\$)\Z/xi-sm');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in complex regex tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Regex';
        is $item->value, qr/(?xi-sm:\Afoo\$bar\%baz\@qux (\@.\%.\$)\Z)/x, 'regex in tree has correct value';
    }
}

sub numbers: Tests {

    {   # simple integer
        explain 'simple integer tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('23');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in simple integer tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Number';
        is $item->value, 23, 'number in tree has correct value';
    }

    {   # negative float with delimiters
        explain 'float tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('-17_500.333');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'correct number of items';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Number';
        is $item->value, -17500.333, 'negative float with delimiter item has correct value';
    }

    {   # zero-point float
        explain 'zero point float: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('0.5');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'correct number of items';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Number';
        is $item->value, 0.5, 'zero-point float item has correct value';
    }
}

sub keywords: Tests {

    {   # simple keyword
        explain 'simple keyword tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform(':foo');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in simple keyword tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Keyword';
        is $item->value, 'foo', 'keyword in tree has correct value';
    }

    {   # swapped doublecolon keyword
        explain 'simple keyword tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('foo:');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in simple keyword tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Keyword';
        is $item->value, 'foo', 'keyword in tree has correct value';
    }
}

sub strings: Tests {

    {   # simple characters
        explain 'simple character tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('#\space');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in simple character tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::String';
        is $item->value, ' ', 'string in character tree has correct value';
    }

    {   # plain string
        explain 'plain string: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('"xyz"');
        isa_ok $tree, TreeClass;
        my $str = $tree->get_content_item(0);
        string_ok $str, 'xyz', 'plain string';
    }

    {   # string with newline
        explain 'string with newline: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('"foo\nbar"');
        isa_ok $tree, TreeClass;
        my $str = $tree->get_content_item(0);
        string_ok $str, "foo\nbar", 'string with newline';
    }

    {   # string with var interpolation
        explain 'string with var: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('"foo ${bar} baz"');
        isa_ok $tree, TreeClass;
        my $ls = $tree->get_content_item(0);
        list_ok $ls, 'string application',
            content_count => 4,
            content_test  => [
                sub { builtin_ok $_, 'string append builtin', value => 'string' },
                sub { string_ok  $_, 'foo ', 'first plain string part' },
                sub { symbol_ok  $_, 'interpolated symbol', value => 'bar' },
                sub { string_ok  $_, ' baz', 'second plain string part' },
            ];
    }

    {   # string with apply interpolation
        explain 'string with apply: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('"foo $(join sep (list 1 2 3)) bar"');
        isa_ok $tree, TreeClass;
        my $ls = $tree->get_content_item(0);
        list_ok $ls, 'string application for interpolation',
            content_count => 4,
            content_test  => [
                sub { builtin_ok $_, 'string append builtin', value => 'string' },
                sub { string_ok  $_, 'foo ', 'first plain string part' },
                sub {
                    list_ok $_, 'interpolated application',
                        content_count => 3,
                        content_test  => [
                            sub { symbol_ok $_, 'application operand', value => 'join' },
                            sub { symbol_ok $_, 'symbolic argument',   value => 'sep' },
                            sub {
                                list_ok $_, 'list argument',
                                    content_count => 4,
                                    content_test  => [
                                        sub { symbol_ok $_, 'list constructor', value => 'list' },
                                        sub { number_ok $_, 1, 'first number in list' },
                                        sub { number_ok $_, 2, 'second number in list' },
                                        sub { number_ok $_, 3, 'third number in list' },
                                    ];
                            },
                        ];
                },
                sub { string_ok  $_, ' bar', 'second plain string part' },
            ];
    }

    my $self = self;

    throws_ok { $self->transform('"foo ${bar"') } 'Script::SXC::Exception::ParseError',
        'unclosed var interpolation';
    like $@, qr/variable interpolation/i, 'unclosed var interpolation message';

    throws_ok { $self->transform('"foo $(bar"') } 'Script::SXC::Exception::ParseError',
        'unclosed apply interpolation';
    like $@, qr/applied interpolation/i, 'unclosed apply interpolation message';

    throws_ok { $self->transform('"foo $(bar [baz)) qux"') } 'Script::SXC::Exception::ParseError',
        'invalid apply expression';
    like $@, qr/expected/i, 'invalid apply expression message';
}

sub booleans: Tests {

    {   # simple boolean
        explain 'simple boolean tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('#yes');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'single item in simple boolean tree';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Boolean';
        is $item->value, 1, 'boolean in tree has correct value';
    }
}

sub comments: Tests {

    {   # comment removal
        explain 'symbol with comment tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('foo; bar ; baz');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'only one item in tree with comments';
        isa_ok my $item = $tree->get_content_item(0), 'Script::SXC::Tree::Symbol';
        is $item->value, 'foo', 'symbol in tree has correct value';
    }
}

sub cells: Tests {
    my $self = self;

    {   # unexpected closing parens
        throws_ok { $self->transform(')') } 'Script::SXC::Exception::ParseError',
            'unexpected closing parens throws parse error';
        like $@, qr/unexpected closing parenthesis/i, 'error message looks good';
        like $@, qr/'\)'/, 'error message contains wrong parenthesis';
        is $@->type, 'unexpected_close', 'thrown exception has correct parse error type';
    }

    {   # simple cell with symbol
        explain 'list with symbol: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('(foo)');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'tree contains one item';
        isa_ok my $list = $tree->get_content_item(0), 'Script::SXC::Tree::List';
        is $list->content_count, 1, 'list contains one item';
        isa_ok my $item = $list->get_content_item(0), 'Script::SXC::Tree::Symbol';
        is $item->value, 'foo', 'symbol in list has correct value';
    }

    {   # more complex tree
        explain 'more complex tree: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('(foo [bar] baz)');
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'tree contains one item (should be list)';
        isa_ok my $list = $tree->get_content_item(0), 'Script::SXC::Tree::List';
        is $list->content_count, 3, 'list contains three items (should be symbol, list, symbol)';
        my @items = @{ $list->contents };
        isa_ok $items[0], 'Script::SXC::Tree::Symbol';
        isa_ok $items[1], 'Script::SXC::Tree::List';
        isa_ok $items[2], 'Script::SXC::Tree::Symbol';
        is $items[0]->value, 'foo', 'first symbol has correct value';
        is $items[2]->value, 'baz', 'last symbol has correct value';
        is $items[1]->content_count, 1, 'sublist contains one item (should be symbol)';
        isa_ok my $subitem = $items[1]->get_content_item(0), 'Script::SXC::Tree::Symbol';
        is $subitem->value, 'bar', 'symbol in list has correct value';
    }

    {   
        my $self = self;

        # unexpected end of stream
        throws_ok { $self->transform('(foo bar') } 'Script::SXC::Exception::ParseError',
            'unexpected end throws parse error';
        like $@, qr/unexpected end/i, 'error message seems ok';
        like $@, qr/'\)'/, 'error message contains expected parenthesis';
        is $@->type, 'unexpected_end', 'parse error has correct type';

        # wrong closing parens
        throws_ok { $self->transform('(foo]') } 'Script::SXC::Exception::ParseError',
            'parenthesis mismatch throws parse error';
        like $@, qr/expected/i, 'error message seems ok';
        is $@->type, 'parenthesis_mismatch', 'parse error type correct';
    }
}

sub inline_hashes: Tests {

    {   # simple creation
        explain 'inline hash: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform('{foo: 23 bar: 42}');
        is $tree->content_count, 1, 'inline hash parses into single item';
        $tree = $tree->get_content_item(0);
        isa_ok $tree, 'Script::SXC::Tree::Hash';
        is $tree->content_count, 4, 'inline hash has correct number of values';
        isa_ok $tree->get_content_item(0), 'Script::SXC::Tree::Keyword';
        isa_ok $tree->get_content_item(1), 'Script::SXC::Tree::Number';
        isa_ok $tree->get_content_item(2), 'Script::SXC::Tree::Keyword';
        isa_ok $tree->get_content_item(3), 'Script::SXC::Tree::Number';
    }
}

sub quoting: Tests {

    {   # simple quote
        explain 'simple quote: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform(q/(foo 'bar)/);
        is $tree->content_count, 1, 'tree contains one item';
        isa_ok my $list = $tree->get_content_item(0), 'Script::SXC::Tree::List';
        is $list->content_count, 2, 'list contains two items';
        isa_ok $list->get_content_item(0), 'Script::SXC::Tree::Symbol';
        is $list->get_content_item(0)->value, 'foo', 'first symbol has correct value';
        isa_ok my $quote = $list->get_content_item(1), 'Script::SXC::Tree::List';
        is $quote->content_count, 2, 'quote list contains symbol and one value';
        isa_ok my $symbol = $quote->get_content_item(0), 'Script::SXC::Tree::Builtin';
        isa_ok my $quoted = $quote->get_content_item(1), 'Script::SXC::Tree::Symbol';
        isa_ok $symbol, 'Script::SXC::Tree::Symbol';
        is $symbol->value, 'quote', 'symbol is quote builtin';
        is $quoted->value, 'bar', 'quoted symbol has correct value';
    }

    {   # quasiquote and unquotes
        explain 'quasiquote and unquotes: ',
            dump assert_ok 'tree built ok',
            my $tree = self->transform(q/(foo `[bar ,baz ,@(qux)])/);
        isa_ok $tree, TreeClass;
        is $tree->content_count, 1, 'tree has one item';
        my $list = $tree->get_content_item(0);
        list_ok $list, 'single list in tree',
            content_count => 2,
            content_test  => [
                sub { symbol_ok $_, 'first symbol', value => 'foo' },
                sub { 
                    quote_ok $_, 'quasiquoted content',
                        quote_name => 'quasiquote',
                        quote_test => sub {
                            list_ok $_, 'quoted list',
                                content_count => 3,
                                content_test  => [
                                    sub { symbol_ok $_, 'first symbol in quoted list', value => 'bar' },
                                    sub {
                                        quote_ok $_, 'unquoted symbol',
                                            quote_name => 'unquote',
                                            quote_test => sub {
                                                symbol_ok $_, 'second unquoted symbol in quoted list', 
                                                    value => 'baz';
                                            };
                                    },
                                    sub {
                                        quote_ok $_, 'spliced unquoted application',
                                            quote_name => 'unquote-splicing',
                                            quote_test => sub {
                                                list_ok $_, 'application',
                                                    content_count => 1,
                                                    content_test  => [
                                                        sub { symbol_ok $_, 'third unquoted symbol', value => 'qux' },
                                                    ];
                                            };
                                    },
                                ];
                        };
                },
            ];
    }
}

1;
