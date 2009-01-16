package Script::SXC::Exception;
use Moose;

use Script::SXC::Types qw( Str Int );

use Perl6::Caller;
use PadWalker       qw( peek_my );
use Data::Dump      qw( dump );
use Scalar::Util    qw( blessed );

use namespace::clean -except => 'meta';
use overload '""' => sub { (shift)->error_message }, fallback => 1;
use Method::Signatures;

with 'Script::SXC::SourcePosition';

has message => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    builder     => 'build_default_message',
    lazy        => 1,
);

has type => (
    is          => 'rw',
    isa         => Str,
);

method build_default_message { undef }

method throw_to_caller ($class: :$message!, :$type!, :$up?, :$line_number, :$source_description) {

    my $vars = peek_my(defined($up) ? $up : 2);
#    warn dump $vars;
    if (exists $vars->{'$___SXC_CALLER_INFO___'}) {
        my $cinfo = ${ $vars->{'$___SXC_CALLER_INFO___'} };
        return $class->throw(
            type    => $type,
            message => $message,
            %$cinfo,
        );
    }

    my $c = defined($up) ? caller($up) : caller(2);
    return $class->throw(
        type                => $type,
        message             => $message,
        source_description  => sprintf('(package %s, subroutine %s, file %s)', $c->package, $c->subroutine, $c->filename),
        line_number         => $c->line,
    );
}

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

__PACKAGE__->meta->make_immutable;

1;
