

  J I T A C  -  Image to ASCII Converter 
  (c) 2001 by Konrad Rieck <kr@roqe.org> - http://www.roqe.org/jitac
- ------------------------------------------------------------------

  
- Introduction

  Jitac is an image to ASCII converter written in Java. Yes, you guessed
  right, this is a cute console application that converts high-quality
  images into oldschool ASCII art. If you find this idea ridicilous, well,
  better don't read on.


- How it works

  Jitac reads a source image that can have one of the following formats:
  GIF, JPEG, TIFF, PNG, PICT, Photoshop, BMP, Targa, ICO, CUR, Sunraster,
  XBM, XPM and PCX. Jitac also reads in a font which can be chosen from a
  list of integrated fonts or loaded from a BDF font file. The result of the
  image to ASCII conversion strongly depends on the chosen font.  Images
  rendered with a font and displayed with another font may look really
  weird.

  Before the conversion some filters and optional features can be applied to
  the source image, e.g. inversion, resizing/scaling, gamma correction.  The
  conversion is done by dividing the image into blocks that have equal size
  and whose dimensions match the charakter dimensions. For each block the
  charakter is chosen that best matches the pixels inside the block.
  Features such as noise or rounding (often used in neural networks) can be
  used to improve conversion quality.

  By default Jitac uses all visible ASCII charakters in the range 32-126,
  but Jitac also allows using different ranges or even a specified set of
  charakters for converting an image, e.g. the set " .o0O".


- Installation and execution

  Actually there is no big kind of installation, just copy the Jitac Jar
  Archive to a folder and you are ready. You can now execute Jitac by
  running the following command in this directory:
    
    java -jar jitac.jar

  You can also obtain the source at http://www.roqe.org/jitac. 


- Commandline options

     -c          Keep coloured source image. By default Jitac uses       
                 a grayscaled copy of the source image. Working on the
                 coloured source image may increase conversion quality.
                                                               
     -h          Print help.
            
     -i          Invert source image. Usefull if converting for a white on 
                 black screen, e.g. old BBX systems.

     -v          Be verbose during conversion.

     -V          Print version and copyright information.

     -r          Round input vectors to 0 or 1. By default Jitac uses
                 values in the range of 0 to 1, rounding the input vectors
                 increases contrast of the source image.

     -g <g>      Apply gamma value <g> to the source image. If you are 
                 converting photos it is often necessary to adjust the gamma
                 value. The default gamma value is 1.0

     -n <n>      Add noise to weight vectors. By default Jitac doesnt't add
                 any noise. By adding noise the conversion processes gets
                 more fuzzy, this increases conversion quality if the source
                 image contains a lot of gradients.

     -s <w>x<h>  Resize source image to geomertry <w>x<h>.

     -S <w>x<h>  Scale width by <w> and height by <h>.

     -o <file>   Write ASCII image to <file>. By default Jitac prints the
                 ASCII images to standard output.

     -w <w>      Scale the source image so that the ASCII image width is
                 <w> characters. A useful option for creating ASCII 
                 art in terminals or mails that have a default character
                 width, in most cases 80. 
                 
     -l <url>    Load a BDF font from URL <url>, e.g. file:fonts/test.bdf.
                 The Xfree package contains a lot of BDF fonts. 

     -L          Print a list of all integrated fonts. Most common fonts
                 are part of Jitac. 

     -f <fn>     Load an intergrated font. See -L. By default Jitac uses
                 the font "courier10" which is typically used on webpages
                 and postscript printouts. 

     -x <s>-<e>  Use characters from <s> to <e>. Values must be integers. 
                 By default Jitac uses all visible ASCII characters, 
                 range 32-126. 

     -X <str>    Use only characters from the string <str> for conversion.
                 Be sure to escape problematic characters such as backslash.


- Credits

  Jitac has been written by Konrad Rieck. Jitac makes use of Jimi, the 
  Java Image Manipulation Interface provided by Sun Microsystems. See the
  file Jimi-License for license information. GetOpt routines have been 
  written by Aaron M. Renn.


