package Script::SXC::Test::Reader;
use strict;
use parent 'Script::SXC::Test';
use self;
use CLASS;
use Test::Most;
use aliased 'Script::SXC::Reader', 'ReaderClass';

CLASS->mk_accessors(qw( reader ));

sub setup_reader: Test(startup) {
    self->reader(ReaderClass->new);
}

sub basic: Tests {
    isa_ok self->reader, ReaderClass;
}

sub string_streams: Tests {
    my $stream = self->reader->build_stream(\'(foo bar)');
    isa_ok $stream, 'Script::SXC::Reader::Stream';
    ok defined $stream->source, 'stream has source';
    ok $stream->source->does('Script::SXC::Reader::Source'), 'source is valid';
    isa_ok $stream->source, 'Script::SXC::Reader::Source::String';
}

1;
