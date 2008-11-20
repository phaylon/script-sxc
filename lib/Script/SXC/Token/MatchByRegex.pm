package Script::SXC::Token::MatchByRegex;
use Moose::Role;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

#requires qw(
#    match_regex
#    build_tokens
#);

method match ($stream) {
#sub match {
#    my ($self, $stream) = @_;

    # test if we match
    my $rx   = $self->match_regex;
    my $line = $stream->line_buffer;

    # only regex specifications get end markers
    my $end  = (ref $rx eq 'Regexp') ? qr/(?=>\b|\s|\)|\]|;|$)/ : qr//;

    # string specifications get quoted
    $rx = qr/\Q$rx\E/ unless ref $rx;

    # an array reference becomes quoted alternatives
    if (ref $rx eq 'ARRAY') {
        my @vals = map { qr/\Q$_\E/ } @$rx;
        my $vals = join '|', @vals;
        $rx = qr/$vals/;
    }

    # try to match full specification against line or stop here
    $line =~ s{^ ($rx) $end }{}x
        or return undef;

    # set rest of the line as buffer if matched
    $stream->line_buffer($line);

    # return tokens in array reference
    return [ $self->build_tokens($1, $stream) ];
};

1;
