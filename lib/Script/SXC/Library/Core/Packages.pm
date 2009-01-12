package Script::SXC::Library::Core::Packages;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Exception::Runtime;
use Script::SXC::Runtime::Validation;
use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use Class::Inspector;
use Data::Dump qw( pp );

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_procedure('require',
    firstclass => sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion('require', [@_], min => 1);
        eval { require Class::Inspector->filename($_); 1 } or Script::SXC::Exception::Runtime->throw(
            type    => 'require_failed',
            message => "Could not require package $_: $@",
        ) for @_;
        return 1;
    },
    inline_fc => 1,
    runtime_req => ['Validation', '+Script::SXC::Exception::Runtime', '+Class::Inspector'],
    inliner => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        $compiler->add_required_package($_)
            for qw( Class::Inspector Script::SXC::Exception::Runtime );
        my $package_var = Variable->new_anonymous('package');
        return CompiledValue->new(typehint => 'number', content => sprintf
            '(do { for my %s (%s) { eval { %s; 1 } or %s } 1 })',
            $package_var->render,
            join(', ', 
                map { $_->compile($compiler, $env, to_string => 1) } @$exprs,
            ),
            sprintf('require Class::Inspector->filename(%s)', 
                $package_var->render,
            ),
            sprintf('Script::SXC::Exception::Runtime->throw(%s, %s)',
                sprintf('message => "Could not require package %s: $@"',
                    $package_var->render,
                ),
                pp( type    => 'require_failed',
                    $symbol->source_information,
                ),
            ),
        );
    },
);

1;
