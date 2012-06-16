package PRFTest;

use strict;
use warnings;

use base 'TestBase';

use Test::More;
use Test::Fatal;

use App::PRF;

sub instance : Test {
    my $self = shift;

    ok($self->_build_prf);
}

sub _build_prf {
    my $self = shift;

    return App::PRF->new(@_);
}

1;
