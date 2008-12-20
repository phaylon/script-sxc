#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Script::SXC::Test::Library::Data::Hashes;

Script::SXC::Test::Library::Data::Hashes->run_customized;
