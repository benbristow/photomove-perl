# PhotoMove Perl Script

[![Validate PR](https://github.com/benbristow/photomove-perl/actions/workflows/main.yml/badge.svg)](https://github.com/benbristow/photomove-perl/actions/workflows/main.yml)

A simple Perl script that emulates the Windows [PhotoMove](https://www.mjbpix.com/automatically-move-photos-to-directories-or-folders-based-on-exif-date/) tool with default settings for Canon and Panasonic LUMIX cameras. This script organizes your photos into a directory structure based on the date the photo was taken.

**Note:** This script was created quickly and may not be production-ready. Use with caution and always back up your files before running!

## Features

- Organizes photos based on EXIF date information
- Works with Canon and Panasonic LUMIX camera files (can be adapted for other cameras)
- Creates a directory structure like:
  ```
  pictures
  └───2024
      └───2024_01
          └───2024_01_11
              └───20240111_143045.JPG
  ```
- Renames files to match their creation date and time
- Tested and working on macOS and Windows

## Supported Cameras

The script has been tested and confirmed to work with:
- Canon cameras
- Panasonic LUMIX cameras

It may work with other camera brands that use standard EXIF data formats. If you successfully use this script with other camera brands, please let us know so we can update this list!

## File Renaming

The script renames files based on their EXIF data in the following format:

```
YYYYMMDD_HHMMSS.ext
```

For example, a file named `IMG_1234.JPG` taken on January 15, 2024 at 14:30:45 would be renamed to:

```
20240115_143045.JPG
```

If multiple files have the same timestamp, the script appends a counter to ensure unique filenames:

```
20240115_143045.JPG
20240115_143045_001.JPG
20240115_143045_002.JPG
```

This renaming scheme ensures that files are easily identifiable by their creation date and time.

## Requirements

- Perl 5.10 or higher
- [cpanminus](https://metacpan.org/pod/App::cpanminus) for easy dependency installation

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/benbristow/photomove-perl.git
   cd photomove-perl
   ```

2. Install dependencies using cpanminus:
   ```bash
   cpanm --cpanfile cpanfile --installdeps .
   ```

## Usage

Run the script with the following command:

```bash
./photomove.pl <source folder> <destination folder>
```

For example:

```bash
./photomove.pl ~/Downloads/Camera ~/Pictures/Organized
```

### Dry Run

To see what changes would be made without actually moving any files, use the `--dry-run` option:

```bash
./photomove.pl --dry-run <source folder> <destination folder>
```

## macOS and Linux Users

The script has been tested and confirmed to work on macOS. It should also work on most Linux distributions. Ensure you have Perl and cpanminus installed on your system.

## Windows Users

This script is compatible with [Strawberry Perl](https://strawberryperl.com/). Follow these steps:

1. Install Strawberry Perl
2. Open a command prompt and navigate to the script directory
3. Run the installation and usage commands as described above

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)

## Disclaimer

This script is provided as-is, without any warranties. Always backup your files before running any script that moves or modifies them.