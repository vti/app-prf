package App::PRF::Command::list_isa;

use strict;
use warnings;

use base 'App::PRF::Command';

use Class::Load ();
use PPI;
use File::Find ();

sub BUILD {
    my $self = shift;

    $self->{color} = 1 unless defined $self->{color};

    $self->{root} ||= './lib';

    return $self;
}

sub run {
    my $self = shift;
    my ($root) = @_;

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

            $packages{$package} ||= {};
        } || do {
            #warn $@;
        };
    }

    foreach my $package (keys %packages) {
        no strict;
        my @isa = grep {exists $packages{$_}} @{"$package\::ISA"};

        $packages{$package} = {isa => [@isa]};
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

1;
