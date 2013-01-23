package App::PRF::Command::rename_module;

use strict;
use warnings;

use base 'App::PRF::Command';

use Cwd            ();
use File::Basename ();
use File::Copy     ();
use File::Find     ();
use File::Path     ();
use PPI;

sub BUILD {
    my $self = shift;

    $self->{root} ||= './lib';

    return $self;
}

sub run {
    my $self = shift;
    my ($from, $to) = @_;

    my $from_path = $self->_class_to_path($from);
    my $to_path   = $self->_class_to_path($to);

    $self->_move_file($from_path, $to_path);

    $self->_replace_package_name($to, $to_path);

    $self->_replace_module_occurencies($from, $to);

    return $self;
}

sub _replace_module_occurencies {
    my $self = shift;
    my ($from, $to) = @_;

    my $to_path = $self->_class_to_path($to);

    my @files;
    File::Find::find(
        {   wanted => sub {
                return unless /\.p(m|l)$/;
                return if /^\Q$to_path\E$/;

                push @files, $_;
            },
            no_chdir => 1,
            follow   => 0
        },
        $self->{root}
    );

    foreach my $file (@files) {
        my $ppi = PPI::Document->new($file);

        my $package = $ppi->find_first('PPI::Statement::Package');
        next unless $package && $package->namespace;

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
                        if ($token->string eq $from) {
                            $token->set_content(q{'} . $to . q{'});
                        }
                    }
                }
                next;
            }

            next unless $node->module;

            if ($node->module eq $from) {
                $node->find('PPI::Token::Word')->[1]->set_content($to);
            }
        }

        my $statements = $ppi->find('PPI::Statement') || [];
        foreach my $node (@$statements) {
            my $words = $node->find('PPI::Token::Word') || [];
            foreach my $word (@$words) {
                if ($word->content eq $from) {
                    $word->set_content($to);
                }
            }
        }

        $ppi->save($file);
    }
}

sub _class_to_path {
    my $self = shift;
    my ($class) = @_;

    my $path = $class . '.pm';
    $path =~ s{::}{/}g;
    $path = File::Spec->catfile($self->{root}, $path);

    return $path;
}

sub _replace_package_name {
    my $self = shift;
    my ($class, $class_path) = @_;

    my $ppi = PPI::Document->new($class_path);
    my $package = $ppi->find_first('PPI::Statement::Package');
    my $name = $package->find('PPI::Token::Word')->[1];
    $name->set_content($class);
    $ppi->save($class_path);
}

sub _move_file {
    my $self = shift;
    my ($from, $to) = @_;

    File::Path::make_path(File::Basename::dirname($to));
    File::Copy::move($from, $to);

    $self->_remove_empty_dirs(File::Basename::dirname($from));
}

sub _remove_empty_dirs {
    my $self = shift;
    my ($dir) = @_;

    while (rmdir $dir) {
        $dir = $self->_cleanup_path(File::Spec->catfile($dir, File::Spec->updir));
    }
}

sub _cleanup_path {
    my $self = shift;
    my ($path) = @_;

    my @parts = ();
    foreach my $part (File::Spec->splitdir($path)) {
        if ($part eq '..') {
            pop @parts;
        }
        elsif ($part ne '.') {
            push @parts, $part;
        }
    }

    return @parts == 0 ? '.' : File::Spec->catdir(@parts);
}

1;
