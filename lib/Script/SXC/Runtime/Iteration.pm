package Script::SXC::Runtime::Iteration;
use 5.010;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Bool ArrayRef );

use Script::SXC::Runtime qw( apply );

use Scalar::Util qw( blessed );

use aliased 'Script::SXC::Runtime::Iterator::End';

use namespace::clean -except => 'meta';

requires qw( clear next_step current_value );

has end_of_stream => (
    is          => 'rw',
    isa         => Bool,
);

has cache => (
    is          => 'rw',
    isa         => ArrayRef,
);

method to_list {
    return [@{ $self->cache }]
        if $self->cache;

    my @contents;
    until ($self->is_end(my $value = $self->next_step)) {
        push @contents, $value;
    }

    $self->cache(\@contents);
    return \@contents;
}

method end {

    $self->clear;
    $self->end_of_stream(1);
    return End->singleton;
}

method is_end ($value) {

    return( defined($value) 
        and blessed($value)
        and $value->isa(End)
    );
}

method apply_current ($appl) {

    @_ = ($appl, [$self->current_value]);
    goto &apply;
}

1;
