package App::PRF::Finder;

use strict;
use warnings;

use File::Find ();

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub find {
    my $self = shift;
    my (@paths) = @_;

    @paths = ('./lib') unless @paths;

    my @files;
    for my $path (@paths) {
        if (-f $path) {
            push @files, $path;
            next;
        }

        die "Can't open '$path': $!\n" unless -d $path;

        File::Find::find(
            {   wanted => sub {
                    return unless /\.p(m|l)$/;

                    push @files, $_;
                },
                no_chdir => 1,
                follow   => 0
            },
            $path
        );
    }

    return @files;
}

1;
