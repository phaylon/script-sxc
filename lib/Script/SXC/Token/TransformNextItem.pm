package Script::SXC::Token::TransformNextItem;
use Moose::Role;

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';
#use Method::Signatures;

requires qw(
    end_of_stream_error_message
    transform_item
);

sub transform {
    my ($self, $stream) = @_;
    
    # prepare next token
    my $token = $stream->next_token
        or ParseError->throw(
            type                => 'unexpected_end',
            message             => 'Unexpected end of input: ' . $self->end_of_stream_error_message,
            line_number         => $self->line_number,
            source_description  => $self->source_description,
        );

    # transform into the next item
    my $item = $token->transform($stream);

    # prepare the item
    return $self->transform_item($item, $stream);
};

1;
