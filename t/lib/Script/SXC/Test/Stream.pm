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

CLASS->mk_accessors(qw( reader ));

{   # utility functions

    sub assert_ok {
        my ($msg, $val, @rest) = @_;
        ok $val, $msg;
        return wantarray ? ($val, @rest) : $val;
    }
}

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
        explain 'dot tree',
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
            my $tree = self->transform('foo ; bar ; baz');
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
    }
}

1;
