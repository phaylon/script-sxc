package Script::SXC::Compiled::SyntaxRules::CaptureHandling;
use Moose::Role;
use MooseX::Method::Signatures;

use signatures;

sub apply_at ($store, $coord, $code) {

    $store = \$_[0]
        unless ref $store;

    unless (@$coord) {
        return $code->($store);
    }

    my $index = $coord->[-1];
    my $ref   = @$coord == 1 ? \($store->[ $index ]) : $store->[ $index ];

    @_ = ($ref, [ @{ $coord }[ 0 .. ($#$coord - 1) ] ], $code);
    goto \&apply_at;
}

use namespace::clean -except => 'meta';

method set_capture_value (ArrayRef $captures, ArrayRef $coordinates, $value) {
    return apply_at($captures, $coordinates, sub ($store) { $$store = $value });
}

method get_capture_value (ArrayRef $captures, ArrayRef $coordinates) {
    return apply_at($captures, $coordinates, sub ($store) { $$store });
}

1;
