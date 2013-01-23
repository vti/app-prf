package App::PRF::Command::list_classes;

use strict;
use warnings;

use base 'App::PRF::Command';

use PPI;
use App::PRF::Finder;
use App::PRF::PPI::ExtractISA;

use constant IS_IN_HELL => $^O eq 'MSWin32';

sub BUILD {
    my $self = shift;

    $self->{color} = 1 unless defined $self->{color};

    return $self;
}

sub run {
    my $self = shift;
    my (@paths) = @_;

    my @files = $self->_find_files(@paths);

    my %packages;

    foreach my $file (@files) {
        my $ppi = PPI::Document->new($file, readonly => 1);

        my $package = $ppi->find_first('PPI::Statement::Package');
        next unless $package && $package->namespace;
        $package = $package->namespace;

        my @isa = App::PRF::PPI::ExtractISA->new->extract($ppi);

        $packages{$package} = {isa => [@isa]};
    }

    my $isa_printer;
    $isa_printer = sub {
        my ($package) = @_;

        foreach my $isa (@{$packages{$package}->{isa}}) {
            my $arrow = !IS_IN_HELL && $self->{color} ? "\e[0;31m<\e[0m" : '<';
            print " $arrow ", $isa;
            $isa_printer->($isa);
        }
    };

    foreach my $package (sort keys %packages) {
        print $package;

        $isa_printer->($package);
        print "\n";
    }
}

sub _find_files {
    my $self = shift;
    my (@paths) = @_;

    return App::PRF::Finder->new->find(@paths);
}

1;
