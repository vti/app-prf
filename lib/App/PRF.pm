package App::PRF;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub run {
    my $self = shift;
    my ($command, @args) = @_;

    $command = $self->_build_command($command);

    $command->run(@args);
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
