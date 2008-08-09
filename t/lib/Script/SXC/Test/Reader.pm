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

sub string_streams: Tests {

    # build stream
    explain 'stream object: ', dump my $stream = self->reader->build_stream(\"(foo bar)\n(baz qux)");
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
    is $source->line_content, "(foo bar)\n", 'first line content in string source correct';
    is $source->line_number, 1, 'string source starts at line number 1';
    ok !$source->end_of_stream, 'end of stream not yet reached';

    # test second line
    is $source->next_line, "(baz qux)\n", 'second line is correct after next_line';
    is $source->line_content, "(baz qux)\n", 'second line also correct in content';
    is $source->line_number, 2, 'correct line number';
    ok $source->end_of_stream, 'reached end of stream';

    # test stream reset
    ok !defined($source->next_line), 'next line is undefined after end of stream';
    is $source->line_number, 0, 'line number reset to 0 after end of stream';
    ok !$source->has_line_content, 'no line content after end of stream';
}

1;
