package Script::SXC::Token::Comment;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::EmptyTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

#method match ($stream) {
sub match {
    my ($self, $stream) = @_;
    my $class = ref($self) || $self;

    # the line needs to start with a semicolon for us to match
    return undef unless $stream->line_buffer =~ /^;+\s*(.+)$/;

    # create token class and empty the line to its end
    my $token = $class->new(value => $1);
    $stream->line_buffer('');

    # return comment token
    return [ $token ];
};

__PACKAGE__->meta->make_immutable;

1;
