#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use File::Copy;
use Image::ExifTool;
use DateTime::Format::Strptime;
use File::Path qw(make_path);

my @file_extensions = qw(mp4 cr3);
my $dir_format = '%Y_%m/%Y_%m_%d/';

sub get_file_extension ($file) {
    my ($ext) = $file =~ /\.([^.]+)$/;
    return $ext;
}

sub is_valid_extension ($file) {
    my $ext = get_file_extension($file);
    return grep { lc($ext) eq lc($_) } @file_extensions;
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
    $target_dir = $target_dir . '/' . $file_date->strftime($dir_format);

    make_path($target_dir) if (! -d $target_dir);

    my $target_file = $target_dir . (split('/', $source_file))[-1];
    if (-e $target_file) {
        print "File $target_file already exists, skipping\n";
    } else {
        print "Moving $source_file to $target_file\n";
        move($source_file, $target_file) || die "Could not move $source_file to $target_file: $!\n";
    }
}

sub main ($source_dir, $target_dir) {
    die "Usage: $0 <source directory> <target directory>\n" if (! $source_dir || ! $target_dir);

    die "Source directory $source_dir does not exist\n" if (! -d $source_dir);
    die "Target directory $target_dir does not exist\n" if (! -d $target_dir);

    my @files = get_file_list($source_dir);
    print "Found " . scalar(@files) . " files\n";
    foreach my $file (@files) {
        move_file($file, $target_dir);
    }

    print "Done\n";
}

main(@ARGV);