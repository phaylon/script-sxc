#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Script::SXC::Test::Library::Core::Sequences;

Script::SXC::Test::Library::Core::Sequences->run_customized;

