package Script::SXC::Compiled;
use Moose;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Script::SXC::Types  qw( ArrayRef Bool Str );
use Scalar::Util        qw( blessed );
use List::MoreUtils     qw( uniq );

use namespace::clean -except => 'meta';

has expressions => (
    metaclass       => 'Collection::Array',
    is              => 'rw',
    isa             => ArrayRef,
    required        => 1,
    default         => sub { [] },
    provides        => {
        'push'          => 'add_expression',
    },
);

has use_strict => (
    is              => 'rw',
    isa             => Bool,
    default         => 1,
);

has use_warnings => (
    is              => 'rw',
    isa             => Bool,
    default         => 0,
);

has pre_text => (
    is              => 'rw',
    isa             => Str,
);

has required_packages => (
    metaclass       => 'Collection::Array',
    is              => 'rw',
    isa             => ArrayRef[Str],
    required        => 1,
    default         => sub { [] },
    provides        => {
        'push'          => 'add_required_package',
    },
);

has required_types => (
    metaclass       => 'Collection::Array',
    is              => 'rw',
    isa             => ArrayRef[Str],
    required        => 1,
    default         => sub { [] },
    provides        => {
        'count'         => 'required_types_count',
    },
);

method evaluate {

    my $handler = $self->evaluated_callback;
    my $value   = $handler->();         # the coderef allows zero-level gotos to work

    return $value;
};

method evaluated_callback {
    local $@;

    my $body    = $self->get_full_body;
    my $handler = eval sprintf 'sub { %s }', $body
        or die "Could not compile Perl code: $@\n";

    return $handler;
};

my $EvalCount = 0;

method get_full_body {
    my $body = $self->get_body;     # must come first to populate required packages, etc.
    return join ';', 
        sprintf('package Script::SXC::Compiled::EVAL%d', $EvalCount),
        ( $self->use_strict   ? 'use strict'          : 'no strict' ),
        ( $self->use_warnings ? 'use warnings'        : 'no warnings' ),
        'use 5.010',
        'use IO::Handle',
        ( $self->pre_text     ? $self->pre_text . ';' : () ),
        ( map  { sprintf 'require %s', $_ } 
          uniq 
               qw( Scalar::Util ),
               @{ $self->required_packages },
        ),
        $body;
};

method get_body {
    return join '; ', map { $_->render } @{ $self->expressions };
};

__PACKAGE__->meta->make_immutable;

1;
