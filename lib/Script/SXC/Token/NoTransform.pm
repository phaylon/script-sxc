package Script::SXC::Token::NoTransform;
use Moose::Role;

use aliased 'Script::SXC::Exception';

use namespace::clean -except => 'meta';
use Method::Signatures;

method transform {
    my $class = ref($self) || $self;

    Exception->throw(
        message             => "Cannot transform $class token",
        line_number         => $self->line_number,
        source_description  => $self->source_description,
    );
};

1;
