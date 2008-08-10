package Script::SXC::Token::Character;
use Moose;

use Script::SXC::Types qw( Str );

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

my %CharacterMap = (
    'newline'       => "\n",
    'tab'           => "\t",
    'space'         => ' ',
);

method match_regex { 
    qr/
        \#\\
        [a-z]
        [a-z0-9_-]*
        [a-z0-9]
    /xi
};

method build_tokens ($value, $stream) {
    my $class = ref($self) || $self;
    
    # normalise char name
    $value = lc $value;
    $value =~ /^#\\(.+)$/;
    my $spec = $1;

    # defined character
    if (defined $CharacterMap{ $spec }) {
        $value = $CharacterMap{ $spec };
    }

    # unicode character
    elsif ($spec =~ /^u([0-9a-f]+)$/i) {
        # FIXME
    }

    # no idea
    else {
        ParseError->throw(
            type                => 'unknown_char',
            message             => "Don't know how to handle character specification '$spec'",
            line_number         => $stream->source_line_number,
            source_description  => $stream->source_description,
        );
    }

    # return token
    return $class->new(value => $value);
};

1;
