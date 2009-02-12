package Script::SXC::Token::Invalid::Number;
use Moose;

use Script::SXC::Types qw( Num );

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::NoTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Num);

method match_regex { 
    qr/
        [+-]?
        \d
        .*
        \b
    /xi
};

method build_tokens ($value, $stream) {
    my $class = ref($self) || $self;

    ParseError->throw(
        type                => 'invalid_number',
        message             => "Invalid number specification: $value",
        line_number         => $stream->source_line_number,
        source_description  => $stream->source_description,
    );
};

__PACKAGE__->meta->make_immutable;

1;
