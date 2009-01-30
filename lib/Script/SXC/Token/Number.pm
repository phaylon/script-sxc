package Script::SXC::Token::Number;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Num Object );

use Math::BigRat;

use namespace::clean -except => 'meta';

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::DirectTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Num | Object );

method match_regex { 
#sub match_regex {
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
          |                     # rationals
            (?:
                \d+
                \/
                \d+
            )
          |                     # integer and float
            (?:                 # 24_800.30
                [1-9][_\d]+\d
                |               # 24.30
                [1-9]\d*
                |
                0               # simple non-octal 0
            )
            (?:\.\d+)?
        )
    /xi
};

#sub build_tokens {
#    my ($self, $value) = @_;
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
    elsif ($value !~ /\./ and $value =~ /^0(.+)$/) {
        $value = oct $1;
    }

    # rational value
    elsif ($value =~ /\//) {
        $value = Math::BigRat->new($value);
    }

    # move value into negative if it was signed negative
    $value = 0 - $value
        if $substract;

    # return number, force coercion to num context
    return $class->new(value => 0+$value);
};

method tree_item_class () { 'Script::SXC::Tree::Number' }
#sub tree_item_class { 'Script::SXC::Tree::Number' };

__PACKAGE__->meta->make_immutable;

1;
