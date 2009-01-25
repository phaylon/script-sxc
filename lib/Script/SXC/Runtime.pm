package Script::SXC::Runtime;
use 5.010;
use strict;
use warnings;

use constant RuntimeKeywordClass => 'Script::SXC::Runtime::Keyword';
use constant RuntimeRangeClass   => 'Script::SXC::Runtime::Range';

use Script::SXC::lazyload
    [RuntimeKeywordClass, 'RuntimeKeyword'],
    RuntimeRangeClass,
    ['Script::SXC::Runtime::Iterator::List', 'ListIterator'],
    'Script::SXC::Exception',
    'Script::SXC::Exception::ArgumentError',
    'Script::SXC::Exception::TypeError';

use Scalar::Util qw( blessed );

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

sub make_iterator ($source) {

    # source is an object
    if (blessed $source) {

        # transform range source to iterator
        if ($source->isa(RuntimeRangeClass)) {
            return ListIterator->new(list => [@{ $source->to_iterator }]);
        }

        # unknown object source
        else {
            die "Error in iteration typecheck"
        }
    }

    # treat source as a list
    else {
        return ListIterator->new(list => [@{ $source }]);
    }
}

sub make_keyword ($value) {
    return $KeywordSingleton{ $value }
        if exists $KeywordSingleton{ $value };
    return( $KeywordSingleton{ $value } = RuntimeKeyword->new(value => $value) );
}

sub range {

    # remove indices from arguments
    my @indices;
    push @indices, shift @_
        while @_ and not(blessed($_[0]) and $_[0]->isa(RuntimeKeywordClass));

    # check and init index arguments
    ArgumentError->throw_to_caller(
        type    => 'invalid_range_indices',
        message => 'Invalid range indices',
    ) if @indices < 1 or @indices > 2;
    my ($end, $start) = reverse @indices;
    $start //= 0;

    # do not create range objects for small constant ranges
    if (not(@_) and not ref($end) and not ref($start)) {
        return [$start .. $end]
            if $end - $start < 32;
    }

    # check and init options
    ArgumentError->throw_to_caller(
        type    => 'invalid_argument_list',
        message => 'Even list of options and values expected after range indices',
    ) if scalar(@_) % 2;
    my %options = @_;

    # stepper defaults to increase by 1
    my $step = exists($options{step}) ? delete($options{step}) : sub { shift(@_) + 1 };

    # bark if we had unknown options
    if (my @unknown = keys %options) {
        ArgumentError->throw_to_caller(
            type    => 'invalid_range_options',
            message => 'Invalid range options: ' . join(', ', @unknown),
        );
    }

    # build range object
    return Range->new(
        stepper     => $step,
        start_at    => $start,
        stop_at     => $end,
    );
}

sub apply {
    for my $x (60 .. 10) {
        no warnings;
        say "$x: ", join ', ', (caller($x))[0..2];
    }

    # we need at least two arguments
    ArgumentError->throw_to_caller(
        type    => 'missing_arguments',
        message => 'Missing arguments: apply expects at least 2 arguments',
        up      => 1,
    ) unless @_ >= 2;

    # split up the arguments
    my ($invocant, @args) = @_;

    # last argument must be list
    ArgumentError->throw_to_caller(
        type    => 'invalid_argument_type',
        message => 'Invalid argument type: Last argument to apply must be a list',
        up      => 1,
    ) unless (ref $args[-1] eq 'ARRAY') 
          or (blessed($args[-1]) and $args[-1]->isa(RuntimeRangeClass));

    # reformat arguments to apply to
    push @args, @{ pop @args };

    # invocant swap for keywords
    if (blessed($invocant) and $invocant->isa(RuntimeKeywordClass)) {
        my $new_invocant = shift @args;
        unshift @args, $invocant;
        $invocant = $new_invocant;
    }

    # prepare for goto
    @_ = @args;

    # dispatch based on type
    given (ref $invocant) {
        when ('CODE') {
#            return $invocant->(@args);
            goto $invocant;
        }
        when ('ARRAY') {
            ArgumentError->throw_to_caller(
                type    => 'invalid_argument_count',
                message => 'Invalid argument count: list application expects single argument (index)',
            ) unless @args == 1;
            return $invocant->[ $args[0] ];
        }
        when ('HASH') {
            ArgumentError->throw_to_caller(
                type    => 'invalid_argument_count',
                message => 'Invalid argument count: hash application expects single argument (key)',
            ) unless @args == 1;
            return $invocant->{ $args[0] };
        }
        default {
            if (defined $invocant and not ref $invocant) {
                ArgumentError->throw_to_caller(
                    type    => 'missing_arguments',
                    message => 'Missing arguments for class method call on string',
                ) unless @_ >= 1;
                TypeError->throw_to_caller(
                    type    => 'invalid_invocant_type',
                    message => "Invalid class name for method call: '$invocant'",
                ) unless $invocant =~ /^\D/;
                my $method_name = shift;
                my $method = $invocant->can("$method_name") or Exception->throw_to_caller(
                    type    => 'missing_method',
                    message => "Unable to call method '$method_name' on class $invocant",
                );
                #return $invocant->$method(@args);
                unshift @_, $invocant;
                goto $method;
            }
            elsif (blessed $invocant and not $invocant->isa('Script::SXC::Runtime::Object')) {
                ArgumentError->throw_to_caller(
                    type    => 'missing_arguments',
                    message => 'Missing arguments for class method call on string',
                ) unless @_ >= 1;
                my $method_name = shift;
                my $method = $invocant->can("$method_name") or Exception->throw_to_caller(
                    type    => 'missing_method',
                    message => "Unable to call method '$method_name' on class " . ref($invocant),
                );
                #return $invocant->$method(@args);
                unshift @_, $invocant;
                goto $method;
            }
            else {
                TypeError->throw_to_caller(
                    type    => 'invalid_invocant_type',
                    message => 'Invocant for application needs to be code, object, list or hash',
                    # TODO missing source information
                );
            }
        }
    }
}

1;
