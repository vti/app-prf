package App::PRF::Command::inspect;

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
}

sub run {
    my $self = shift;
    my ($root, $class) = @_;

    die "Can't open '$root': $!\n" unless -d $root;

    unshift @INC, $root;

    my $path_to_class = $class . '.pm';
    $path_to_class =~ s{::}{/}g;
    $path_to_class = File::Spec->catfile($root, $path_to_class);

    die "Can't open '$path_to_class': $!\n" unless -f $path_to_class;

    my $ppi = PPI::Document->new($path_to_class, readonly => 1);

    my $package = $ppi->find_first('PPI::Statement::Package');
    next unless $package && $package->namespace;
    $package = $package->namespace;

    Class::Load::load_class($package);

    my @isa = do {
        no strict;
        @{"$package\::ISA"};
    };

    print "Package:\n  $package\n";

    if (@isa) {
        print "ISA:\n";
        print "  " . join ', ', @isa;
        print "\n";
    }

    my $GREEN  = !IS_IN_HELL && $self->{color} ? "\e[0;32m" : '';
    my $YELLOW = !IS_IN_HELL && $self->{color} ? "\e[0;33m" : '';
    my $PURPLE = !IS_IN_HELL && $self->{color} ? "\e[0;35m" : '';
    my $RESET  = !IS_IN_HELL && $self->{color} ? "\e[0m"    : '';

    my @inherited_public_methods = $self->_get_inherited_public_methods($ppi, \@isa);
    my @public_methods = $self->_get_public_methods($ppi);
    if (@public_methods || @inherited_public_methods) {
        print "Methods:\n";
        foreach my $method (@inherited_public_methods) {
            print "  $PURPLE$method->{name}$RESET ($method->{parent})\n";
        }
        foreach my $method (@public_methods) {
            print "  $GREEN$method$RESET\n";
        }
    }

    my @inherited_protected_methods = $self->_get_inherited_protected_methods($ppi, \@isa);
    my @protected_methods = $self->_get_protected_methods($ppi);
    if (@protected_methods || @inherited_protected_methods) {
        print "Protected methods:\n";
        foreach my $method (@inherited_protected_methods) {
            print "  $PURPLE$method->{name}$RESET ($method->{parent})\n";
        }
        foreach my $method (@protected_methods) {
            print "  $GREEN$method$RESET\n";
        }
    }
}

sub _get_inherited_public_methods {
    my $self = shift;
    my ($ppi, $isa) = @_;

    my @result;

    foreach my $parent (@$isa) {
        my $path_to_class = $parent . '.pm';
        $path_to_class =~ s{::}{/}g;
        $path_to_class = $INC{$path_to_class};

        my $ppi = PPI::Document->new($path_to_class, readonly => 1);

        push @result,
          map { {name => $_, parent => $parent} }
          $self->_get_public_methods($ppi);
    }

    return @result;
}

sub _get_inherited_protected_methods {
    my $self = shift;
    my ($ppi, $isa) = @_;

    my @result;

    foreach my $parent (@$isa) {
        my $path_to_class = $parent . '.pm';
        $path_to_class =~ s{::}{/}g;
        $path_to_class = $INC{$path_to_class};

        my $ppi = PPI::Document->new($path_to_class, readonly => 1);

        push @result,
          map { {name => $_, parent => $parent} }
          $self->_get_protected_methods($ppi);
    }

    return @result;
}

sub _get_public_methods {
    my $self = shift;
    my ($ppi) = @_;

    return grep { !m/^_/ } $self->_get_package_methods($ppi);
}

sub _get_protected_methods {
    my $self = shift;
    my ($ppi) = @_;

    return grep { m/^_/ } $self->_get_package_methods($ppi);
}

sub _get_package_methods {
    my $self = shift;
    my ($ppi) = @_;

    my @result;
    my $methods = 
      $ppi
      ->find(sub { $_[1]->isa('PPI::Statement::Sub') and $_[1]->name });
    push @result, map { $_->name } @{$methods || []};

    return @result;
}

1;
