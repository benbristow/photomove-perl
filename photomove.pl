#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say signatures);
no warnings 'experimental::signatures';
use File::Copy;
use Image::ExifTool;
use DateTime::Format::Strptime;
use File::Path qw(make_path remove_tree);
use Getopt::Long;
use File::Basename;
use File::Spec;
use Term::ReadKey;
use Time::HiRes qw(usleep);

use constant {
    FILE_EXTENSIONS => [qw(mp4 cr3 jpg rw2 dng)],
    DIR_FORMAT => '%Y/%Y_%m/%Y_%m_%d',
    FILE_FORMAT => '%Y%m%d_%H%M%S',
};

my $dry_run = 0;
GetOptions("dry-run" => \$dry_run) or die "Error in command line arguments\n";

my $spinner_char = 0;

sub update_spinner {
    my @spinner = qw(| / - \\);
    print "\r", $spinner[$spinner_char];
    $spinner_char = ($spinner_char + 1) % 4;
}

sub log_message ($msg) {
    my $date = DateTime->now->strftime('%Y-%m-%d %H:%M:%S');
    say "\r[$date] $msg";
}

sub get_file_extension ($file) {
    return $file =~ /\.([^.]+)$/ ? lc($1) : '';
}

sub is_valid_extension ($file) {
    my $ext = get_file_extension($file);
    return grep { $ext eq lc($_) } @{FILE_EXTENSIONS()};
}

sub get_file_list ($dir) {
    my @files;
    opendir(my $dh, $dir) or die "Can't open $dir: $!";
    while (my $entry = readdir $dh) {
        next if $entry eq '.' or $entry eq '..';
        my $path = File::Spec->catfile($dir, $entry);
        if (-d $path) {
            push @files, get_file_list($path);
        } elsif (is_valid_extension($path)) {
            push @files, $path;
        }
        update_spinner();
    }
    closedir $dh;
    return @files;
}

sub get_file_date ($file) {
    my $exifTool = Image::ExifTool->new;
    my $info = $exifTool->ImageInfo($file);
    my $date = $info->{DateTimeOriginal} || $info->{CreateDate} 
        or die "Could not find date for $file\n";
    $date =~ s/(\d+):(\d+):(\d+) /$1-$2-$3 /;
    return DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%d %H:%M:%S'
    )->parse_datetime($date);
}

sub move_and_rename_file ($source_file, $target_dir, $is_dry_run, $tree) {
    my $file_date = get_file_date($source_file);
    my $new_dir = File::Spec->catdir($target_dir, $file_date->strftime(DIR_FORMAT()));
    my $ext = get_file_extension($source_file);
    my $new_filename = $file_date->strftime(FILE_FORMAT()) . ".$ext";
    my $target_file = File::Spec->catfile($new_dir, $new_filename);

    # Check if the file is already in the correct location with the correct name
    my $source_dir = dirname($source_file);
    my $source_filename = basename($source_file);
    if ($source_dir eq $new_dir && $source_filename eq $new_filename) {
        return;  # Skip this file as it doesn't need to be changed
    }

    # Handle filename conflicts
    my $counter = 1;
    while (-e $target_file) {
        my $existing_ext = get_file_extension($target_file);
        if ($existing_ext ne $ext) {
            # If extensions are different, we can use the same base name
            last;
        }
        $new_filename = $file_date->strftime(FILE_FORMAT()) . "_" . sprintf("%03d", $counter) . ".$ext";
        $target_file = File::Spec->catfile($new_dir, $new_filename);
        $counter++;
    }

    if ($is_dry_run) {
        add_to_tree($tree, $target_file);
    } else {
        make_path($new_dir) unless -d $new_dir;
        log_message("Moving and renaming $source_file to $target_file");
        move($source_file, $target_file) 
            or die "Could not move $source_file to $target_file: $!\n";
    }
    update_spinner();
}

sub add_to_tree ($tree, $path) {
    my @parts = File::Spec->splitdir($path);
    my $current = $tree;
    for my $part (@parts) {
        $current->{$part} //= {};
        $current = $current->{$part};
    }
}

sub render_tree ($tree, $prefix = '') {
    for my $key (sort keys %$tree) {
        say "$prefix$key";
        render_tree($tree->{$key}, $prefix . '    ') if ref $tree->{$key} eq 'HASH';
    }
}

sub get_user_confirmation {
    print "\nDo you want to proceed with the actual file operations? (y/n): ";
    ReadMode('cbreak');
    my $key = ReadKey(0);
    ReadMode('normal');
    print "$key\n";
    return lc($key) eq 'y';
}

sub process_files ($files, $target_dir, $is_dry_run) {
    my $tree = {};
    my $total_files = scalar @$files;
    my $processed_files = 0;
    for my $file (@$files) {
        move_and_rename_file($file, $target_dir, $is_dry_run, $tree);
        $processed_files++;
        print "\rProcessing files: $processed_files/$total_files ";
        update_spinner();
    }
    print "\n";  # Move to the next line after processing is complete
    return $tree;
}

sub remove_empty_directories ($dir, $is_dry_run = 0) {
    my @empty_dirs;
    
    opendir(my $dh, $dir) or die "Can't open $dir: $!";
    my @entries = readdir($dh);
    closedir($dh);

    for my $entry (@entries) {
        next if $entry eq '.' or $entry eq '..';
        my $path = File::Spec->catdir($dir, $entry);
        if (-d $path) {
            push @empty_dirs, remove_empty_directories($path, $is_dry_run);
        }
    }

    if (!grep { $_ ne '.' and $_ ne '..' } @entries) {
        if ($is_dry_run) {
            push @empty_dirs, $dir;
        } else {
            log_message("Removing empty directory: $dir");
            rmdir($dir) or die "Could not remove directory $dir: $!";
        }
    }

    return @empty_dirs;
}

sub main {
    die "Usage: $0 [--dry-run] <source directory> <target directory>\n" 
        if @ARGV < 2;

    my ($source_dir, $target_dir) = @ARGV;
    die "Source directory $source_dir does not exist\n" unless -d $source_dir;
    die "Target directory $target_dir does not exist\n" unless -d $target_dir;
    die "Source and target directories are the same\n" if $source_dir eq $target_dir;

    print "Scanning files... ";
    my @files = get_file_list($source_dir);
    log_message("Found " . scalar(@files) . " files");

    if ($dry_run) {
        my $tree = process_files(\@files, $target_dir, 1);
        my @dirs_to_delete = remove_empty_directories($source_dir, 1);
        
        if (%$tree) {
            say "\nDry run output (files to be moved/renamed):";
            render_tree($tree);
        } else {
            say "\nNo files need to be moved or renamed.";
        }
        
        if (@dirs_to_delete) {
            say "\nDry run: The following empty directories would be deleted:";
            say $_ for @dirs_to_delete;
        }
        
        if (%$tree || @dirs_to_delete) {
            if (get_user_confirmation()) {
                log_message("Proceeding with actual file operations...");
                process_files(\@files, $target_dir, 0);
                remove_empty_directories($source_dir);
            } else {
                log_message("Operation cancelled by user.");
            }
        } else {
            log_message("No changes needed. Exiting.");
        }
    } else {
        process_files(\@files, $target_dir, 0);
        remove_empty_directories($source_dir);
    }

    log_message("Done");
}

main();