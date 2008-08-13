package Script::SXC::Token::Whitespace;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::EmptyTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match ($stream) {
    my $class = ref($self) || $self;

    # fetch whitespaces off current line buffer
    my $line = $stream->line_buffer;
    return undef unless $line =~ s/^(\s+)//ms;
    $stream->line_buffer($line);

    return [ $class->new(value => $1) ];
};

1;
