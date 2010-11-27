use Image::Magick;
use strict;

my $Copyright = 'Copyright 2009-2010 by Jim Leonard (jim@xuth.net)';

# mk_c_font.pl
#
# script to create simple fonts usable by small c programs, ideal
# for embedded environments.  
# 
# This uses ImageMagick to render each character of a font in a 
# specific size, performs some additional processing and then 
# saves the rasterization as a c file that can be included in a 
# program.
#
# All of the parameters for this script are set in the beginning 
# of this script and they are documented enough to use this with
# a bit of experimentation.

# which font available to imagemagick do we wish to use
# you can get a list with "convert -list font"
#my $font = "Nimbus-Sans-Regular";
my $font = "Bitstream-Vera-Sans-Roman";
#my $font = "URW-Bookman-Light";
#my $font = "Palatino-Roman";
#my $font = "Helvetica";

# placing the font on the image is an imperfect art
# and is based on the font and scaling factor
my $placeX = 3;
my $placeY = 10;
my $scale = '2.8,3.5';

# this is a list of sizes for scaling the images.
# resizing an image works best if done in several
# discrete steps rather than one big one
# the first size is what the character is rendered on
# and then the image is resized and subsequent work
# is performed on the final size
my @sizeX = (64, 40, 32, 24, 20);
my @sizeY = (48, 30, 24, 18, 15);

# after the character has been placed and the image
# resampled, pluck the character off this section
# of the image.  The x part is less important since
# it will get calculated based on how much is actually
# used, though it must be big enough to contain all 
# of the rendered character. (if we start making
# non-proportional fonts then this would likely change).  
# The minY/height pair is precise and is copied directly
# to the font size so you should play with those til you 
# get what works best for you.
my $minY = 0;
my $height = 15;
my $minX = 0;
my $width = 23;

# how wide is the space character
my $spaceWidth = 2;

# how much space between characters
my $betweenWidth = 1;

# what file do we save the font in
my $filename = "simple_font_15.c";
# name of the structure in the c file
my $dataname = "simple_font_15";


my @char_width;

open FILE, ">$filename" or die "Can't create $filename\n   $!";

# now write out a space
$char_width[32] = $spaceWidth;
printf FILE "static unsigned char %s_%03d[] = { /*   */\n", $dataname, 32;
for (my $i = 0; $i < $height; ++$i) {
    print FILE "        ";
    for (my $j = 0; $j < $spaceWidth; ++$j) {
        printf FILE "%3d,", 0;
    }
    print FILE "\n";
}
print FILE "    };\n";

my $sc = @sizeX;
my $x;
my $image;

for (my $c = 33; $c <= 126; ++$c) {
    my $size = "$sizeX[0]x$sizeY[0]";
    $image = Image::Magick->new('size'=>$size);
    $x = $image->Read('xc:black');
    warn "$x" if "$x";

    my $char = chr($c);
    $char = "\\'" if $c == 39;  # wtf?  IM expects escaping within the API!!!

    print("Drawing char $char\n");
    
    $x = $image->Set(stroke=>'white');
    warn "$x" if "$x";
#    $x = $image->Set(strokewidth=>'0');
    warn "$x" if "$x";
    $x = $image->Set(fill=>'white');
    warn "$x" if "$x";
    $x = $image->Set(font=>$font);
    warn "$x" if "$x";

    my $points = "$placeX,$placeY";

    $x = $image->Draw(
        primitive=>'text',
        scale=>$scale,
        text=>$char,
        strokewidth=>'0.0',
        points=>$points,
        );

    warn "$x" if "$x";

    for (my $a = 1; $a < $sc; ++$a) {
        $x = $image->Resize(width=>$sizeX[$a], height=>$sizeY[$a]);
        warn "$x" if "$x";
    }

    # don't know if I prefer the double sharpen or not...
    $image->AdaptiveSharpen(radius=>'1');
    $image->AdaptiveSharpen(radius=>'1');

    # uncomment if we want to write this out
    #$x = $image->Write(filename=>"font_char_$c.png");
    #warn "$x" if "$x";

    # we only need one channel of pixels... we really should be doing
    # this in monochrome... whatever
    my @pixels = $image->GetPixels(width=>$width, height=>$height,
                                   x=>$minX, 'y'=>$minY, map=>'R', normalize=>0);

    for (my $i = 0; $i < $width * $height; ++$i) {
        $pixels[$i] = int($pixels[$i] / 256);
        $pixels[$i] = 255 if $pixels[$i] > 255;
        $pixels[$i] = 0 if $pixels[$i] < 0;
    }

    #print "@pixels\n";

    # first find the left edge and right edges
    my $le = -1;  # left edge
    my $re = -1;  # right edge
    for (my $x = 0; $x < $width; ++$x) {
        for (my $y = 0; $y < $height; ++$y) {
            if ($pixels[$x + $y * $width] > 20) {
                $re = $x;
                $le = $x if $le == -1;
                last;
            }
        }
    }
    print "left edge: $le, right edge: $re\n";
    warn "no pixels on for char $char!" if $le == -1;
    $le = 0 if $le == -1;

    my $cw = $re - $le + 1; # character width

    $char_width[$c] = $cw;

    printf FILE "static unsigned char %s_%03d[] = {  /* $char */\n", $dataname, $c;
    for (my $y = 0; $y < $height; ++$y) {
        print FILE "        ";
        for (my $x = 0; $x < $cw; ++$x) {
            printf FILE "%3d,", $pixels[$y * $width + $x + $le];
        }
        print FILE "\n";
    }
    print FILE "    };\n";
    
    @$image = ();
}
print FILE "\n\n";
print FILE "struct {\n";
print FILE "    int min_c;  /* ascii code of first char */\n";
print FILE "    int max_c;  /* ascii code of last char */\n";
print FILE "    int height;  /* height of the font */\n";
print FILE "    int between_width;  /* width of space between characters */\n";
print FILE "    struct {\n";
print FILE "        int width;  /* width of the character */\n";
print FILE "        unsigned char *data; /* one byte per pixel, width first */\n";
print FILE "    } c[95];\n";
print FILE "} $dataname = { 32, 126, $height, $betweenWidth, {\n";
for (my $i = 32; $i <= 126; ++$i) {
    printf FILE "    { $char_width[$i], %s_%03d },\n", $dataname, $i;
}

print FILE "    } };\n";



undef $image;

    
    
