#!/usr/bin/perl
use strict;
use inc::Module::Install;

name            'Script-SXC';
author          'Robert \'phaylon\' Sedlacek <rs@474.at>';
license         'perl';
perl_version    '5.008008';

all_from        'lib/Script/SXC.pm';

test_requires   'Test::Class';
test_requires   'Test::Most';

requires        'namespace::clean',         '0.08';
requires        'Method::Signatures',       '0.02';
requires        'Moose',                    '0.57';
requires        'MooseX::Types',            '0.05';
requires        'MooseX::AttributeHelpers', '0.13';
requires        'aliased';
requires        'Data::Dump';
requires        'CLASS';

no_index        directory   => 'examples';

WriteAll;
