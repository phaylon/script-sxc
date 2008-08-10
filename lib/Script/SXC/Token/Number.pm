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
        [+-]?
        (?:
            0[xb]
            (?:
                [\da-f]
                [\da-f_]*
                [\da-f]
              |  
                [\da-f]+
            )
          |
            (?:
                \d+[_\d]+\d+
                |
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
