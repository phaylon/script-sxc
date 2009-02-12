package Script::SXC::Token::Invalid::Keyword;
use Moose;

use Script::SXC::Types qw( Str );

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::NoTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match_regex { 
    qr/
        : .* \b
    /xi
};

method build_tokens ($value, $stream) {
    my $class = ref($self) || $self;

    ParseError->throw(
        type                => 'invalid_keyword',
        message             => "Invalid keyword specification: $value",
        line_number         => $stream->source_line_number,
        source_description  => $stream->source_description,
    );
};

__PACKAGE__->meta->make_immutable;

1;
