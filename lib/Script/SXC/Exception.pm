package Script::SXC::Exception;
use Moose;

use Script::SXC::Types qw( Str Int );

use Scalar::Util qw( blessed );

use namespace::clean -except => 'meta';
use Method::Signatures;
use overload '""' => sub { (shift)->error_message }, fallback => 1;

with 'Script::SXC::SourcePosition';

has message => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

method throw (%args) {
    my $class = ref($self) || $self;
    die $class->new(%args);
};

method error_message {
    return join '',
        sprintf('[%s] ', blessed $self),
        ( $self->source_description 
          ? sprintf('in %s on line %d: ', $self->source_description, $self->line_number)
          : ''),
        $self->message;
};

1;
