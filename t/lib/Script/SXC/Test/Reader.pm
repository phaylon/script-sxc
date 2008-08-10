package Script::SXC::Test::Reader;
use strict;
use parent 'Script::SXC::Test';
use self;
use CLASS;
use Test::Most;
use aliased 'Script::SXC::Reader', 'ReaderClass';
use Data::Dump qw( dump );

CLASS->mk_accessors(qw( reader ));

sub setup_reader: Test(startup) {
    self->reader(ReaderClass->new);
}

sub basic: Tests {
    isa_ok self->reader, ReaderClass;
}

sub build_stream { self->reader->build_stream(\(args)) }

sub to_tokens { self->build_stream(args)->all }

sub string_sources: Tests {

    # build stream
    explain 'stream object: ', dump my $stream = self->build_stream("(foo bar)\n(baz qux)");
    isa_ok $stream, 'Script::SXC::Reader::Stream';

    # test source
    explain 'source object: ', dump my $source = $stream->source;
    ok defined $source, 'stream has source';
    ok $source->does('Script::SXC::Reader::Source'), 'source is valid';
    isa_ok $source, 'Script::SXC::Reader::Source::String';
    is $source->source_description, '(scalar)', 'correct source description';

    # test pre-fetch
    is $source->line_count, 2, 'correct number of lines in string source';
    is $source->line_number, 0, 'before first line is fetched, line number is 0';

    # test first line
    is $source->line_content, "(foo bar)", 'first line content in string source correct';
    is $source->line_number, 1, 'string source starts at line number 1';
    ok !$source->end_of_stream, 'end of stream not yet reached';

    # test second line
    is $source->next_line, "(baz qux)", 'second line is correct after next_line';
    is $source->line_content, "(baz qux)", 'second line also correct in content';
    is $source->line_number, 2, 'correct line number';
    ok $source->end_of_stream, 'reached end of stream';

    # test stream reset
    ok !defined($source->next_line), 'next line is undefined after end of stream';
    is $source->line_number, 0, 'line number reset to 0 after end of stream';
    ok !$source->has_line_content, 'no line content after end of stream';
}

sub symbol_tokens: Tests {

    explain 'symbol token: ', dump my $symbol = self->to_tokens('foo');
    isa_ok $symbol, 'Script::SXC::Token::Symbol';
    is $symbol->value, 'foo', 'correct symbol value';
    is $symbol->line_number, 1, 'correct line number';
    is $symbol->source_description, '(scalar)', 'correct source description';
}

sub whitespace_tokens: Tests {

    {   # simple whitespace token
        explain 'single whitespace token: ', dump my $ws = self->to_tokens('   ');
        isa_ok $ws, 'Script::SXC::Token::Whitespace';
        is $ws->value, '   ', 'correct whitespace value';
    }
    
    {   # tabular whitespace token
        explain 'tabular whitespace token: ', dump my $ws = self->to_tokens("\t\t");
        isa_ok $ws, 'Script::SXC::Token::Whitespace';
        is $ws->value, "\t\t", 'correct tabular whitespace value';
    }
    
    {   # newline and simple whitespaces
        explain 'tabular whitespace token: ', dump my @ws = self->to_tokens(" \n \n");
        is scalar(@ws), 2, 'newlines give correct number of lines';
        isa_ok $_, 'Script::SXC::Token::Whitespace' 
            for @ws;
        is $_->value, " ", 'correct tabular whitespace value'
            for @ws;
        is $ws[0]->line_number, 1, 'first line number correct';
        is $ws[1]->line_number, 2, 'second line number correct';
    }
}

sub number_tokens: Tests {

    {   # integer
        explain 'integer token: ', dump my $int = self->to_tokens('15');
        isa_ok $int, 'Script::SXC::Token::Number';
        is $int->value, 15, 'correct integer number value';

        # positive
        explain 'positive integer token: ', dump my $posint = self->to_tokens('+15');
        isa_ok $posint, 'Script::SXC::Token::Number';
        is $posint->value, 15, 'correct positive integer number value';

        # negative
        explain 'negative integer token: ', dump my $negint = self->to_tokens('-15');
        isa_ok $negint, 'Script::SXC::Token::Number';
        is $negint->value, -15, 'correct negative integer number value';

        # complex
        explain 'complex integer token: ', dump my $cint = self->to_tokens('-1_500.30');
        isa_ok $cint, 'Script::SXC::Token::Number';
        is $cint->value, '-1500.3', 'correct complex integer number value';
    }

    {   # floats
        explain 'float token: ', dump my $float = self->to_tokens('15.23');
        isa_ok $float, 'Script::SXC::Token::Number';
        is $float->value, '15.23', 'correct float number value';

        explain 'negative float token: ', dump my $negfloat = self->to_tokens('-15.23');
        isa_ok $negfloat, 'Script::SXC::Token::Number';
        is $negfloat->value, '-15.23', 'correct negative float number value';

        explain 'complex float token: ', dump my $cfloat = self->to_tokens('+1_500.23');
        isa_ok $cfloat, 'Script::SXC::Token::Number';
        is $cfloat->value, '1500.23', 'correct complex float number value';
    }

    {   # hex
        explain 'hex token: ', dump my $hex = self->to_tokens('0xFF');
        isa_ok $hex, 'Script::SXC::Token::Number';
        is $hex->value, 0xFF, 'correct hex number value';
    }

    {   # oct
        explain 'oct token: ', dump my $oct = self->to_tokens('0666');
        isa_ok $oct, 'Script::SXC::Token::Number';
        is $oct->value, 0666, 'correct oct number value';
    }
}

sub keyword_tokens: Tests {

    explain 'keyword token: ', dump my $keyword = self->to_tokens(':foo23-bar');
    isa_ok $keyword, 'Script::SXC::Token::Keyword';
    is $keyword->value, 'foo23-bar', 'correct keyword value';
}

1;
