#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Script::SXC::Test::Library::Core::Lambdas;

Script::SXC::Test::Library::Core::Lambdas->run_customized;

