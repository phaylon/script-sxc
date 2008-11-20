package Script::SXC::TypeHinting;
use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( ArrayRef Int Str Maybe );

use Carp qw( croak );

use namespace::clean -except => 'meta';

my $TypeHint = enum 'Script::SXC::Types::TypeHint', 
    qw( number string code list bool keyword symbol scalarref hash );

has typehint => (
    is          => 'rw',
    isa         => Maybe[$TypeHint],
#    lazy        => 1,
    builder     => 'build_default_typehint',
    clearer     => 'clear_typehint',
);

method build_default_typehint { undef }

method render_typehint_comment {

    # return a comment string if we have a typehint, otherwise an empty string
    return $self->typehint ? sprintf(' # %s', $self->typehint) : '';
}

method type_might_be (Str $hint!) {

    # if we don't have a typehint, we don't know
    return 1 unless $self->typehint;

    # otherwise we must have exactly that typehint
    return $self->typehint eq $hint;
}

method try_typehinting_from (Object $item!, Bool :$or_clear?) {

    # see if we can typehint
    if ($item->does('Script::SXC::TypeHinting')) {
        $self->typehint($item->typehint);
    }
    elsif ($or_clear) {
        $self->clear_typehint;
    }
}

1;
