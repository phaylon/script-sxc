#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Script::SXC::Test::Library::Core::Recursions;

Script::SXC::Test::Library::Core::Recursions->run_customized;

