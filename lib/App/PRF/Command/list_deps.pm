package App::PRF::Command::list_deps;

use strict;
use warnings;

use base 'App::PRF::Command';

use Cwd              ();
use File::Basename   ();
use File::Copy       ();
use File::Find       ();
use Module::CoreList ();
use PPI;

sub BUILD {
    my $self = shift;

    $self->{root} ||= './lib';

    return $self;
}

sub run {
    my $self = shift;
    my ($root) = @_;

    $root ||= $self->{root};

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

    my %local_packages;

    my %deps;
    foreach my $file (@files) {
        my $ppi = PPI::Document->new($file);

        my $package = $ppi->find_first('PPI::Statement::Package');
        next unless $package && $package->namespace;
        $package = $package->namespace;

        $local_packages{$package}++;

        my $includes = $ppi->find('Statement::Include') || [];
        for my $node (@$includes) {
            next if grep { $_ eq $node->module } qw{ lib };

            if (grep { $_ eq $node->module } qw{ base parent }) {

                my @meat = grep {
                         $_->isa('PPI::Token::QuoteLike::Words')
                      || $_->isa('PPI::Token::Quote')
                } $node->arguments;

                my @parents = @meat;
                foreach my $token (@parents) {
                    if (   $token->isa('PPI::Token::QuoteLike::Words')
                        || $token->isa('PPI::Token::Number'))
                    {
                    }
                    else {
                        next if $token->content =~ m/^base|parent$/;

                        push @{$deps{$token->string}}, $package;
                    }
                }
                next;
            }

            next unless $node->module;

            push @{$deps{$node->module}}, $package;
        }
    }

    my @core;
    my @deps;

    foreach my $dep (sort keys %deps) {
        next if exists $local_packages{$dep};
        next if grep { $_ eq $dep } (qw/strict warnings utf8/);

        if (Module::CoreList->first_release($dep)) {
            push @core, $dep;
        }
        else {
            push @deps, $dep;
        }
    }

    print "Core:\n\n";
    for (@core) {
        print $_, "\n";
    }
    print "\n";

    print "Non-Core:\n\n";
    for (@deps) {
        print $_, "\n";
    }
}

1;
