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

    my $self = self;
    throws_ok { $self->to_tokens('23foo') } 
        'Script::SXC::Exception::ParseError',
        'symbol that tries to start with number throws parse error';
    is $@->line_number, 1, 'symbol parse error has correct line number';
    is $@->type, 'cannot_parse', 'symbol parse error has correct type';
    like "$@", qr/Unable to parse/i, 'exception error message seems ok';
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

        my $self = self;

        throws_ok { $self->to_tokens('15_') } 'Script::SXC::Exception::ParseError',
            'number ending with _ delimiter throws parse error';
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

        my $self = self;
    
        throws_ok { $self->to_tokens('15.2.3') } 'Script::SXC::Exception::ParseError',
            'float with two commas throws parse error';
        throws_ok { $self->to_tokens('14_.23') } 'Script::SXC::Exception::ParseError',
            'float with _ delimiter before comma throws parse error';
    }

    {   # bin
        explain 'bin token: ', dump my $bin = self->to_tokens('0b110');
        isa_ok $bin, 'Script::SXC::Token::Number';
        is $bin->value, 0b110, 'correct bin number value';

        # negative bin
        explain 'negative bin token: ', dump my $nbin = self->to_tokens('-0b11');
        isa_ok $nbin, 'Script::SXC::Token::Number';
        is $nbin->value, -0b11, 'correct negative bin number value';

        # complex bin
        explain 'complex bin token: ', dump my $cbin = self->to_tokens('0b11_10');
        isa_ok $cbin, 'Script::SXC::Token::Number';
        is $cbin->value, 0b1110, 'correct complex bin number value';

        # trailing zeroes
        explain 'trailing zeroes bin token: ', dump my $tzbin = self->to_tokens('0b0010');
        isa_ok $tzbin, 'Script::SXC::Token::Number';
        is $tzbin->value, 0b10, 'trailing zeroes are ignored for binary tokens';

        my $self = self;

        throws_ok { $self->to_tokens('0b1021') } 'Script::SXC::Exception::ParseError',
            'invalid binary number throws exception';
    }

    {   # hex
        explain 'hex token: ', dump my $hex = self->to_tokens('0xFF');
        isa_ok $hex, 'Script::SXC::Token::Number';
        is $hex->value, 0xFF, 'correct hex number value';

        # negative
        explain 'negative hex token: ', dump my $nhex = self->to_tokens('-0xFF');
        isa_ok $nhex, 'Script::SXC::Token::Number';
        is $nhex->value, -0xFF, 'correct negative hex number value';

        # complex
        explain 'complex hex token: ', dump my $chex = self->to_tokens('0xFF_FF');
        isa_ok $chex, 'Script::SXC::Token::Number';
        is $chex->value, 0xFFFF, 'correct complex hex number value';

        my $self = self;

        throws_ok { $self->to_tokens('0xPONY') } 'Script::SXC::Exception::ParseError',
            'invalid hexadecimal number throws exception';
    }

    {   # oct
        explain 'oct token: ', dump my $oct = self->to_tokens('0666');
        isa_ok $oct, 'Script::SXC::Token::Number';
        is $oct->value, 0666, 'correct oct number value';

        # negative oct
        explain 'negative oct token: ', dump my $negoct = self->to_tokens('-0666');
        isa_ok $negoct, 'Script::SXC::Token::Number';
        is $negoct->value, -0666, 'correct negative oct number value';
    }
}

sub keyword_tokens: Tests {

    explain 'keyword token: ', dump my $keyword = self->to_tokens(':foo23-bar');
    isa_ok $keyword, 'Script::SXC::Token::Keyword';
    is $keyword->value, 'foo23-bar', 'correct keyword value';
}

sub character_tokens: Tests {

    {   # newlines
        explain 'newline char: ', dump my $nl = self->to_tokens('#\newline');
        isa_ok $nl, 'Script::SXC::Token::Character';
        is $nl->value, "\n", 'newline character value correct';
    }

    {   # tabs
        explain 'tabular char: ', dump my $tab = self->to_tokens('#\tab');
        isa_ok $tab, 'Script::SXC::Token::Character';
        is $tab->value, "\t", 'tabular character value correct';
    }

    {   # spaces
        explain 'space char: ', dump my $sp = self->to_tokens('#\space');
        isa_ok $sp, 'Script::SXC::Token::Character';
        is $sp->value, ' ', 'space character value correct';
    }
}

sub boolean_tokens: Tests {

    my %tests = (
        '#t'        => 1, 
        '#true'     => 1, 
        '#True'     => 1,
        '#yes'      => 1,
        '#f'        => undef, 
        '#false'    => undef,
        '#FALSE'    => undef,
        '#No'       => undef,
    );
    for my $expr (keys %tests) {
        explain "boolean ($expr) token: ", dump my $tok = self->to_tokens($expr);
        isa_ok $tok, 'Script::SXC::Token::Boolean';
        is $tok->value, $tests{ $expr }, "boolean token value for $expr correct";
    }
}

sub comment_tokens: Tests {

    {   # simple
        explain 'simple comment token: ', dump my @tok = self->to_tokens('foo ; bar ; baz');
        is scalar(@tok), 3, 'correct number of tokens for line with comment';

        # 'foo' <=> ' ' <=> 'bar ; baz'
        isa_ok $tok[0], 'Script::SXC::Token::Symbol';
        is $tok[0]->value, 'foo', 'correct symbol token before comment';
        isa_ok $tok[1], 'Script::SXC::Token::Whitespace';
        is $tok[1]->value, ' ', 'correct whitespace token before comment';
        isa_ok $tok[2], 'Script::SXC::Token::Comment';
        is $tok[2]->value, 'bar ; baz', 'correct comment token';
    }
}

sub cell_tokens: Tests {

    my @tests = (
        ['(', 'Script::SXC::Token::CellOpen',  '('],
        [')', 'Script::SXC::Token::CellClose', ')'],
        ['[', 'Script::SXC::Token::CellOpen',  '['],
        [']', 'Script::SXC::Token::CellClose', ']'],
    );

    for my $test (@tests) {
        my ($expr, $token_class, $value) = @$test;
        explain "cell token '$expr': ", dump my @tok = self->to_tokens($expr);
        isa_ok $tok[0], $token_class;
        is $tok[0]->value, $value, "correct token for '$expr' cell opener";
    }
}

sub quote_tokens: Tests {

    {   # simple quote
        explain 'simple quote: ', dump my $tok = self->to_tokens(q{'});
        isa_ok $tok, 'Script::SXC::Token::Quote';
        is $tok->value, q{'}, 'simple quote token has correct value';
        ok !$tok->is_quasiquote, 'simple quote has no quasiquote flag';
    }

    {   # quasiquote
        explain 'quasi quote: ', dump my $tok = self->to_tokens(q{`});
        isa_ok $tok, 'Script::SXC::Token::Quote';
        is $tok->value, q{`}, 'quasi quote token has correct value';
        ok $tok->is_quasiquote, 'simple quote has quasiquote flag';
    }

    {   # quoted symbol
        explain 'quoted symbol: ', dump my @tok = self->to_tokens(q{'foo});
        isa_ok $tok[0], 'Script::SXC::Token::Quote';
        isa_ok $tok[1], 'Script::SXC::Token::Symbol';
        is $tok[0]->value, q{'}, 'quote token has correct value';
        is $tok[1]->value, 'foo', 'quoted symbol has correct value';
        ok !$tok[0]->is_quasiquote, 'no quasiquote flag';
    }

    {   # quoted cell
        explain 'quoted cell: ', dump my @tok = self->to_tokens(q{`(bar)});
        isa_ok $tok[0], 'Script::SXC::Token::Quote';
        isa_ok $tok[1], 'Script::SXC::Token::CellOpen';
        isa_ok $tok[2], 'Script::SXC::Token::Symbol';
        isa_ok $tok[3], 'Script::SXC::Token::CellClose';
        is $tok[0]->value, q{`}, 'quote token has correct value';
        ok $tok[0]->is_quasiquote, 'quote token has quasiquote flag';
        is $tok[2]->value, 'bar', 'symbol in quoted cell has correct value';
    }

    {   # unquote
        explain 'unquote token: ', dump my $tok = self->to_tokens(q{,});
        isa_ok $tok, 'Script::SXC::Token::Unquote';
        is $tok->value, q{,}, 'unquote token has correct value';
        ok !$tok->is_splicing, 'unquote token has no splicing flag';
    }

    {   # unquote-splicing
        explain 'splicing unquote token: ', dump my $tok = self->to_tokens(q{,@});
        isa_ok $tok, 'Script::SXC::Token::Unquote';
        is $tok->value, q{,@}, 'splicing unquote token has correct value';
        ok $tok->is_splicing, 'splicing unquote token has splicing flag';
    }

    {   # unquote symbol
        explain 'unquote symbol tokens: ', dump my @tok = self->to_tokens(',foo');
        is scalar(@tok), 2, 'correct number of tokens for unquoted symbol';
        isa_ok $tok[0], 'Script::SXC::Token::Unquote';
        isa_ok $tok[1], 'Script::SXC::Token::Symbol';
        is $tok[0]->value, ',', 'unquote token has correct value';
        is $tok[1]->value, 'foo', 'unquoted symbol token has correct value';
    }

    {   # splice unquoted list
        explain 'unquoted splice example tokens: ', dump my @tok = self->to_tokens('(foo ,@(bar) baz)');
        my @token_classes = qw( 
            CellOpen 
                Symbol 
                Whitespace 
                Unquote 
                CellOpen 
                    Symbol 
                CellClose 
                Whitespace
                Symbol
            CellClose
        );
        is scalar(@tok), scalar(@token_classes), 'correct number of tokens in unquoted splicing example';
        for my $i (0 .. $#token_classes) {
            isa_ok $tok[ $i ], join '::', 'Script::SXC::Token', $token_classes[ $i ];
        }
        is $tok[1]->value, 'foo', 'first symbol token has correct value';
        is $tok[3]->value, ',@', 'unquote splicing token has correct value';
        is $tok[5]->value, 'bar', 'spliced unquoted symbol token has correct value';
        is $tok[8]->value, 'baz', 'last symbol token has correct value';
        ok $tok[3]->is_splicing, 'unquote splicing token has splicing flag set';
    }
}

sub dot_token: Tests {

    explain 'dot token: ', dump my $dot = self->to_tokens('.');
    isa_ok $dot, 'Script::SXC::Token::Dot';
    is $dot->value, '.', 'dot token has correct value';

    explain 'pair token: ', dump my @pair = self->to_tokens('(foo . bar)');
    my @token_classes = qw( CellOpen Symbol Whitespace Dot Whitespace Symbol CellClose );
    is scalar(@pair), scalar(@token_classes), 'pair parses to correct number of tokens';
    isa_ok $pair[ $_ ], 'Script::SXC::Token::' . $token_classes[ $_ ]
        for 0 .. $#token_classes;
    is $pair[1]->value, 'foo', 'first symbol token has correct value';
    is $pair[3]->value, '.', 'dot token has correct value';
    is $pair[5]->value, 'bar', 'second symbol token has correct value';
}

1;
