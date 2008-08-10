package Script::SXC::Token::MatchByRegex;
use Moose::Role;

use namespace::clean -except => 'meta';
use Method::Signatures;

requires qw(
    match_regex
    build_tokens
);

sub match {
    my ($self, $stream) = @_;

    # test if we match
    my $rx   = $self->match_regex;
    my $line = $stream->line_buffer;
    $line =~ s{^($rx)}{} or return undef;
    $stream->line_buffer($line);

    # return tokens in array reference
    return [ $self->build_tokens($1) ];
};

1;
