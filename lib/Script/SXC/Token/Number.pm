package Script::SXC::Token::Number;
use Moose;

use Script::SXC::Types qw( Num );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

has '+value' => (isa => Num);

method match_regex { 
    qr/
        [+-]?                   # signedness
        (?:                     # octal
            0
            (?:                 # 07_55
                [0-7]
                [0-7_]*
                [0-7]
              |                 # 07
                [0-7]
            )
          |                     # binary
            0b
            (?:                 # 0b0010_1110
                [01]
                [01_]*
                [01]
              |                 # 0b1
                [01]
            )
          |                     # hexadecimal
            0x
            (?:                 # 0xDEAD_BEEF
                [\da-f]
                [\da-f_]*
                [\da-f]
              |                 # 0xF
                [\da-f]+
            )
          |                     # integer and float
            (?:                 # 24_800.30
                \d+[_\d]+\d+
                |               # 24.30
                \d+
            )
            (?:\.\d+)?
        )
    /xi;
};

method build_tokens ($value) {
    my $class = ref($self) || $self;

    # remove sign, remember if it was negative
    $value =~ s/^([+-])//;
    my $substract = $1 eq '-';
    
    # remove spacer bars from number (2_000 => 2000)
    $value =~ s/_//g;

    # hexadecimal value
    if ($value =~ /^0x(.+)$/) {
        $value = hex $1;
    }

    # binary value
    elsif ($value =~ /^0b(.+)$/) {
        $value = eval $value; # FIXME
    }

    # octal value
    elsif ($value =~ /^0(.+)$/) {
        $value = oct $1;
    }

    # move value into negative if it was signed negative
    $value = 0 - $value
        if $substract;

    # return number, force coercion to num context
    return $class->new(value => 0+$value);
};

1;
