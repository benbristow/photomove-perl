# PhotoMove Perl Script

[![Validate PR](https://github.com/benbristow/photomove-perl/actions/workflows/main.yml/badge.svg)](https://github.com/benbristow/photomove-perl/actions/workflows/main.yml)

Simple Perl script to emulate the Windows [PhotoMove](https://www.mjbpix.com/automatically-move-photos-to-directories-or-folders-based-on-exif-date/) tool with default settings for Canon cameras

Whipped this up in an hour or so, not production-worthy - use with caution!

## Usage

* Install [cpanminus](https://metacpan.org/pod/App::cpanminus)

```bash
cpanm --cpanfile cpanfile --installdeps . # Install dependencies using cpanminus
./photomove.pl <source folder> <dest folder>
```