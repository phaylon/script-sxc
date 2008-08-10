package Script::SXC::Token::Character;
use Moose;

use Script::SXC::Types qw( Str );

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

method build_tokens ($value) {
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
        die "Parse Error: $value\n"; # FIXME
    }

    # return token
    return $class->new(value => $value);
};

1;
