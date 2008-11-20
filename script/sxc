#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;
BEGIN {
    if (-e "$FindBin::Bin/../MANIFEST.SKIP") {
        unshift @INC, "$FindBin::Bin/../lib";
        require Script::SXC::Script::Message;
        Script::SXC::Script::Message
            ->new(text => "Added '$FindBin::Bin/../lib' to \@INC")
            ->print;
    }
}

use Script::SXC::Script -run;
#Script::SXC::Script->new_from_options->run;
