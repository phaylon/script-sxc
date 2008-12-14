package Script::SXC::Runtime;
use 5.010;
use strict;
use warnings;

use aliased 'Script::SXC::Runtime::Keyword', 'RuntimeKeyword';
use aliased 'Script::SXC::Exception::ArgumentError';
use aliased 'Script::SXC::Exception::TypeError';

use Sub::Exporter -setup => {
    exports => [qw(
        make_keyword
        make_symbol
        apply
    )],
};

use signatures;
use namespace::clean -except => [qw( import )];

my %KeywordSingleton;

sub make_keyword ($value) {
    return $KeywordSingleton{ $value }
        if exists $KeywordSingleton{ $value };
    return( $KeywordSingleton{ $value } = RuntimeKeyword->new(value => $value) );
}

sub apply {

    # we need at least two arguments
    ArgumentError->throw_to_caller(
        type    => 'missing_arguments',
        message => 'Missing arguments: apply expects at least 2 arguments'
    ) unless @_ >= 2;

    # split up the arguments
    my ($invocant, @args) = @_;

    # last argument must be list
    ArgumentError->throw_to_caller(
        type    => 'invalid_argument_type',
        message => 'Invalid argument type: Last argument to apply must be a list'
    ) unless ref $args[-1] eq 'ARRAY';

    # reformat arguments to apply to
    push @args, @{ pop @args };
    @_ = @args;

    # dispatch based on type
    given (ref $invocant) {
        when ('CODE') {
            goto $invocant;
        }
        when ('ARRAY') {
            ArgumentError->throw_to_caller(
                type    => 'invalid_argument_count',
                message => 'Invalid argument count: List access application expects index',
            ) unless @args == 1;
            return $invocant->[ $args[0] ];
        }
        when ('HASH') {
            ArgumentError->throw_to_caller(
                type    => 'invalid_argument_count',
                message => 'Invalid argument count: Hash access application expects key',
            ) unless @args == 1;
            return $invocant->{ $args[0] };
        }
        default {
            TypeError->throw(
                type    => 'invalid_invocant_type',
                message => 'Invocant for application needs to be code, object, list or hash',
                # TODO missing source information
            );
        }
    }
}

1;
