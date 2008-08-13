package Script::SXC::Token::Invalid::String;
use Moose;

use Script::SXC::Types qw( Str );

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
use Method::Signatures;

extends 'Script::SXC::Token::Symbol';
with    'Script::SXC::Token::NoTransform';

has '+value' => (isa => Str);

method match_regex {
    qr/".+/xsm;
};

method build_tokens ($value, $stream) {
    my $class = ref($self) || $self;

    ParseError->throw(
        type                => 'invalid_string',
        message             => "Invalid string (maybe runaway?) found: $value",
        line_number         => $stream->source_line_number,
        source_description  => $stream->source_description,
    );
};

1;
