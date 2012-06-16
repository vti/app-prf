package TestBase;

use strict;
use warnings;

use base 'Test::Class';

INIT { Test::Class->runtests unless $ENV{TEST_SUITE} }

1;
