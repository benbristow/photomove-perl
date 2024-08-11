#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use File::Copy;
use Image::ExifTool;
use DateTime::Format::Strptime;
use File::Path qw(make_path);

use constant FILE_EXTENSIONS => qw(mp4 cr3 jpg);
use constant DIR_FORMAT => '%Y/%Y_%m/%Y_%m_%d/%H%M%S';

sub print_log ($msg) {
    my $date = DateTime->now->strftime('%Y-%m-%d %H:%M:%S');
    print "[$date] $msg\n";
}

sub get_file_extension ($file) {
    my ($ext) = $file =~ /\.([^.]+)$/;
    return $ext;
}

sub is_valid_extension ($file) {
    my $ext = get_file_extension($file);
    return grep { lc($ext) eq lc($_) } FILE_EXTENSIONS;
}

sub get_file_list ($dir) {
    my @files = ();
    opendir(my $dh, $dir) || die "Can't open $dir: $!";
    while (readdir $dh) {
        my $file = "$dir/$_";
        next if $_ eq '.' or $_ eq '..';
        if (-d $file) {
            push @files, get_file_list($file);
        } else {
            my $ext = get_file_extension($file);
            if (is_valid_extension($file)) {
                push @files, $file;
            }
        }
    }

    return @files;
}

sub get_file_date ($file) {
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo($file);

    my $date = $info->{DateTimeOriginal} || $info->{CreateDate} || die "Could not find date for $file\n";
    $date =~ s/(\d+):(\d+):(\d+) (\d+):(\d+):(\d+)/$1-$2-$3 $4:$5:$6/;
    $date = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S')->parse_datetime($date);

    return $date;
}

sub move_file ($source_file, $target_dir) {
    my $file_date = get_file_date($source_file);
    $target_dir = $target_dir . '/' . $file_date->strftime(DIR_FORMAT);

    make_path($target_dir) if (! -d $target_dir);

    my $target_file = $target_dir . (split('/', $source_file))[-1];
    if (-e $target_file) {
        print_log("File $target_file already exists, skipping");
    } else {
        print_log("Moving $source_file to $target_file");
        move($source_file, $target_file) || die "Could not move $source_file to $target_file: $!\n";
    }
}

sub main {
    die "Usage: $0 <source directory> <target directory>\n" if (scalar(@_) < 2);

    my $source_dir = shift;
    my $target_dir = shift;

    die "Source directory $source_dir does not exist\n" unless -d $source_dir;
    die "Target directory $target_dir does not exist\n" unless -d $target_dir;
    die "Source and target directories are the same\n" if $source_dir eq $target_dir;

    my @files = get_file_list($source_dir);
    print_log("Found " . scalar(@files) . " files");
    foreach my $file (@files) {
        move_file($file, $target_dir);
    }

    print_log("Done");
}

main(@ARGV);
