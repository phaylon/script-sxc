package Script::SXC::lazyload;
use strict;

use Class::MOP;
use Sub::Install;

sub import {
    my ($self, @classes) = @_;

    for my $class (@classes) {
        my $alias;
        if (ref $class) {
            ($class, $alias) = @$class;
        }
        else {
            $class =~ /::([a-z]+)$/i;
            $alias = $1;
        }
        Sub::Install::install_sub {
            code => sub () { 
                warn "# lazyloading: $class\n" 
                    if $ENV{SXC_VERBOSE_LAZYLOAD} and not Class::MOP::is_class_loaded($class);
                Class::MOP::load_class($class);
                return $class;
            },
            into => scalar(caller),
            as   => $alias,
        };
    }
}

1;
