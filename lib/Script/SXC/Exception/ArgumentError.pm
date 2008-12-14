package Script::SXC::Exception::ArgumentError;
use Moose;
use MooseX::Method::Signatures;

use Perl6::Caller;
use PadWalker   qw( peek_my );
use Data::Dump  qw( dump );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception';

method throw_to_caller (Str $class: Str :$message!, Str :$type!, Int :$up?) {

    my $vars = peek_my(defined($up) ? $up : 2);
#    warn dump $vars;
    if (exists $vars->{'$___SXC_CALLER_INFO___'}) {
        my $cinfo = ${ $vars->{'$___SXC_CALLER_INFO___'} };
        return $class->throw(
            type    => $type,
            message => $message,
            %$cinfo,
        );
    }

    my $c = defined($up) ? caller($up) : caller(2);
    return $class->throw(
        type                => $type,
        message             => $message,
        source_description  => sprintf('(package %s, subroutine %s, file %s)', $c->package, $c->subroutine, $c->filename),
        line_number         => $c->line,
    );
}

1;
