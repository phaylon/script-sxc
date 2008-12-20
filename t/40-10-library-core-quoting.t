#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Script::SXC::Test::Library::Core::Quoting;

Script::SXC::Test::Library::Core::Quoting->run_customized;

