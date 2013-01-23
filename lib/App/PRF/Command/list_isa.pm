package App::PRF::Command::list_isa;

use strict;
use warnings;

use base 'App::PRF::Command';

use PPI;
use App::PRF::Finder;
use App::PRF::PPI::ExtractISA;

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

        $packages{$package} ||= {isa => [@isa]};
    }

    my $isa_walker;
    $isa_walker = sub {
        my ($package) = @_;

        foreach my $isa (@{$packages{$package}->{isa}}) {
            push @{$packages{$isa}->{children}}, $package
              unless grep { $_ eq $package } @{$packages{$isa}->{children}};

            $isa_walker->($isa);
        }
    };

    foreach my $package (sort keys %packages) {
        $isa_walker->($package);
    }

    my @roots;
    foreach my $package (sort keys %packages) {

        my $is_a_child = 0;
        foreach my $p (sort keys %packages) {
            if (grep {$_ eq $package} @{$packages{$p}->{children}}) {
                $is_a_child = 1;
                last;
            }
        }

        if (!$is_a_child) {
            push @roots, $package;
        }
    }

    my $child_walker; $child_walker = sub {
        my ($root, $offset) = @_;

        foreach my $child (@{$packages{$root}->{children}}) {
            for (1 .. $offset / 2) {
                print ' + ';
            }
            print $child, "\n";

            $child_walker->($child, $offset + 2);
        }
    };

    foreach my $root (@roots) {
        print $root, "\n";

        $child_walker->($root, 2);
    }
}

sub _find_files {
    my $self = shift;
    my (@paths) = @_;

    return App::PRF::Finder->new->find(@paths);
}

1;
