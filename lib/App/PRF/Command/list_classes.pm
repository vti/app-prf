package App::PRF::Command::list_classes;

use strict;
use warnings;

use base 'App::PRF::Command';

use Class::Load ();
use PPI;
use File::Find ();

use constant IS_IN_HELL => $^O eq 'MSWin32';

sub BUILD {
    my $self = shift;

    $self->{color} = 1 unless defined $self->{color};

    $self->{root} ||= './lib';

    return $self;
}

sub run {
    my $self = shift;
    my ($options, $root) = @_;

    $root ||= $self->{root};
    $root = File::Spec->rel2abs($root);

    die "Can't open '$root': $!\n" unless -d $root;

    my @files;
    File::Find::find(
        {   wanted => sub {
                return unless /\.p(m|l)$/;

                push @files, $_;
            },
            no_chdir => 1,
            follow   => 0
        },
        $root
    );

    my %packages;

    unshift @INC, $root;
    foreach my $file (@files) {
        my $ppi = PPI::Document->new($file, readonly => 1);

        my $package = $ppi->find_first('PPI::Statement::Package');
        next unless $package && $package->namespace;
        $package = $package->namespace;

        eval {
            Class::Load::load_class($package);

            no strict;
            $packages{$package} = {isa => [@{"$package\::ISA"}]};
        } || do {
            #warn $@;
        };
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

1;
