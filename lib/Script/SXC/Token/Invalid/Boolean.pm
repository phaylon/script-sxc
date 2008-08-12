package Script::SXC::Token::Invalid::Boolean;
use Moose;

use Script::SXC::Types qw( Bool );

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Bool);

method match_regex { 
    qr/
        \# \w+
    /xi
};

method build_tokens ($value, $stream) {
    my $class = ref($self) || $self;

    ParseError->throw(
        type                => 'invalid_boolean',
        message             => "Invalid boolean specification: $value",
        line_number         => $stream->source_line_number,
        source_description  => $stream->source_description,
    );
};

1;
