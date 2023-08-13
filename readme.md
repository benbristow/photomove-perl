# PhotoMove Perl Script

Simple Perl script to emulate the Windows [PhotoMove](https://www.mjbpix.com/automatically-move-photos-to-directories-or-folders-based-on-exif-date/) tool with default settings for Canon cameras

Whipped this up in an hour or so, not production-worthy - use with caution!

## Usage

```bash
./photomove.pl <source folder> <dest folder>
```

## CPAN dependencies

```
DateTime::Format::Strptime
Image::ExifTool::Canon
```