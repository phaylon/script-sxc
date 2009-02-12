package Script::SXC::Library::Core::DateTime;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime::Validation;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value',    'CompiledValue'],
    ['DateTime',                        'DateTimeClass'];

use Time::HiRes qw( usleep );

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('sleep',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('sleep', [@_], min => 1, max => 1);
        return Time::HiRes::usleep $_[0] * 1_000_000;
    },
    inline_fc => 1,
    runtime_req => ['Validation', '+Time::HiRes'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
        $compiler->add_required_package('Time::HiRes');
        return CompiledValue->new(content => sprintf
            'Time::HiRes::usleep(%s * 1_000_000)',
            $exprs->[0]->compile($compiler, $env)->render,
        );
    },
);

CLASS->add_procedure('current-timestamp',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('current-timestamp', [@_], max => 0);
        return time;
    },
    inline_fc => 1,
    runtime_req => ['Validation'],
    inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, max => 0);
        return CompiledValue->new(
            typehint => 'number', 
            content  => '(time)',
        );
    },
);

CLASS->add_procedure('current-datetime',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('current-datetime', [@_], max => 0);
        return DateTime->now(time_zone => 'local');
    },
    inline_fc   => 1,
    runtime_req => ['Validation', '+DateTime'],
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, max => 0);
        $compiler->add_required_package('DateTime');
        return CompiledValue->new(
            typehint => 'object', 
            content  => '(DateTime->now(time_zone => "local"))',
        );
    },
);

__PACKAGE__->meta->make_immutable;

1;
