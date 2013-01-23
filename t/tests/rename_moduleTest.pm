package rename_moduleTest;

use strict;
use warnings;

use base 'TestBase';

use Test::More;
use Test::Fatal;

use File::Path ();
use File::Basename ();
use File::Spec;

use App::PRF::Command::rename_module;

sub move_module : Test {
    my $self = shift;

    my $command = $self->_build_command(root => $self->_create_root);

    $self->_mkdir('Foo/Bar');
    $self->_mkfile('Foo/Bar/Baz.pm', 'package Foo::Bar::Baz; 1;');

    $self->_mkfile('Main.pm', '');

    $command->run({}, 'Foo::Bar::Baz', 'Hi::There');

    ok(-f File::Spec->catfile($self->{root}, 'Hi/There.pm'));
}

sub clear_empty_directory : Test {
    my $self = shift;

    my $command = $self->_build_command(root => $self->_create_root);

    $self->_mkdir('Foo/Bar');
    $self->_mkfile('Foo/Bar/Baz.pm', 'package Foo::Bar::Baz; 1;');

    $self->_mkfile('Main.pm', '');

    $command->run({}, 'Foo::Bar::Baz', 'Hi::There');

    ok(!-e File::Spec->catfile($self->{root}, 'Foo'));
}

sub replace_the_package_name : Test {
    my $self = shift;

    my $command = $self->_build_command(root => $self->_create_root);

    $self->_mkdir('Foo/Bar');
    $self->_mkfile('Foo/Bar/Baz.pm', 'package Foo::Bar::Baz; 1;');

    $self->_mkfile('Main.pm', '');

    $command->run({}, 'Foo::Bar::Baz', 'Hi::There');

    is($self->_slurp('Hi/There.pm'), 'package Hi::There; 1;');
}

sub replace_any_occurencies : Test {
    my $self = shift;

    my $command = $self->_build_command(root => $self->_create_root);

    $self->_mkdir('Foo/Bar');
    $self->_mkfile('Foo/Bar/Baz.pm', 'package Foo::Bar::Baz; 1;');

    $self->_mkfile('Main.pm', q{package Main; use base 'Foo::Bar::Baz'; use Foo::Bar::Baz; Foo::Bar::Baz->do(); 1;});

    $command->run({}, 'Foo::Bar::Baz', 'Hi::There');

    is($self->_slurp('Main.pm'), q{package Main; use base 'Hi::There'; use Hi::There; Hi::There->do(); 1;});
}

sub _build_command {
    my $self = shift;

    return App::PRF::Command::rename_module->new(@_);
}

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    local $/;
    open my $fh, '<', File::Spec->catfile($self->{root}, $file);
    return <$fh>;
}

sub _mkdir {
    my $self = shift;
    my ($dir) = @_;

    File::Path::make_path(File::Spec->catfile($self->{root}, $dir));

    return;
}

sub _mkfile {
    my $self = shift;
    my ($file, $content) = @_;

    open my $fh, '>', File::Spec->catfile($self->{root}, $file);
    print $fh $content;

    return;
}

sub _create_root {
    my $self = shift;

    my $root =
      File::Spec->catfile(File::Basename::dirname(__FILE__), '../rename_module');
    $self->{root} = $root;

    if (-e $root) {
        if (-d $root) {
            File::Path::remove_tree($root);
        }
        else {
            die 'Smth is wrong';
        }
    }

    mkdir $root;

    return $self->{root};
}

1;
