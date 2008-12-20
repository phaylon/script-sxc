package Script::SXC::SourcePosition;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str Int Maybe );

use Script::SXC::lazyload
    'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';

has line_number => (
    is          => 'rw',
    isa         => Maybe[Int],
);

has source_description => (
    is          => 'rw',
    isa         => Maybe[Str],
);

has char_number => (
    is          => 'rw',
    isa         => Maybe[Int],
);

method throw_parse_error (Str $type!, Str $message!) {
    ParseError->throw(type => $type, message => $message, $self->source_information);
}

method new_item_with_source (Str $item_type!, HashRef $args = {}) {
    return "Script::SXC::Tree::${item_type}"->new(%$args, $self->source_information);
}

method source_information () {
    return map { ($self->$_ ? ($_ => $self->$_) : ()) } 
        qw( line_number source_description char_number );
}

1;
