package App::PRF;

use strict;
use warnings;

use base 'App::PRF::Base';

our $VERSION = '0.01';

sub run {
    my $self = shift;
    my ($options, $command, @args) = @_;

    $command = $self->_build_command($command);

    $command->run($options, @args);
}

sub _build_command {
    my $self = shift;
    my ($command) = @_;

    $command = "App::PRF::Command::$command";
    my $path = $command . '.pm';
    $path =~ s{::}{/}g;
    require $path;

    return $command->new;
}

1;
