package Script::SXC::Token::Whitespace;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';

with 'Script::SXC::Token::EmptyTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

#method match ($stream) {
sub match {
    my ($self, $stream) = @_;
    my $class = ref($self) || $self;

    # fetch whitespaces off current line buffer
    my $line = $stream->line_buffer;
    return undef unless $line =~ s/^(\s+)//ms;
    $stream->line_buffer($line);

    return [ $class->new(value => $1) ];
};

__PACKAGE__->meta->make_immutable;

1;
