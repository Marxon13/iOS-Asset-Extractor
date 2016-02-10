<img src="https://raw.github.com/Marxon13/iOS-Asset-Extractor/master/ReadmeResources/iOSAssetExtractorBanner.png">

iOS Asset Extractor
=============
iOS Asset Extractor is a tool to extract images from the iOS SDK. It extracts PNGs, PDFs, and CAR files. I made this tool as I base the icons and images I use in my apps off of the images in Apple's stock apps. And it is much easier to have the original files, than it is to take screenshots.

Features:
-------------

* Exports PDF, PNG, and CAR resources.
* Exports image and PDF assets from CAR files.
* Takes a single file, or a directory for searching as input.
* Exports the files to a single directory, or group by the bundle they came from.

Usage:
-------------

**Note:** The iOSAssetExtractor executable must be next to the CARExtractor executable in order for the program to work.

```$ iOSAssetExtractor -i "inputFileOrFolder" -o "outputDirectory" -g 1 -t PDF,CAR,PNG```

The "i" flag is for the input file or directory to export from. If a single file, just that file is exported. If a directory is given, the directory is searched for files to export.

The "o" flag is for the directory that you want the images exported to.

The "g" flag is optional. Set it if you want the output to be grouped by bundle. The flag needs to have a 1 behind it to be set, I wasn't sure how to know the flag was set by "-g". There is a surprising lack of information on building command line tools that take flags... or command line tools in general.

The "t" flag is optional. Set it to only export specific file types. The types should be listed a a comma separated string. The types currently supported are "PDF", "CAR", and "PNG".

Examples:
---------

**Export iOS Simulator SDK:**

```./iOSAssetExtractor -i /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -o /Users/bmcquilkin/Desktop/ExportIOS -g 1```

**Export TVOS Simulator SDK:**

```./iOSAssetExtractor -i /Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk -o /Users/bmcquilkin/Desktop/ExportTV -g 1```

**Export WatchOS Simulator SDK:**

```./iOSAssetExtractor -i /Applications/Xcode.app/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator.sdk -o /Users/bmcquilkin/Desktop/ExportWatch -g 1```

**Export OSX SDK:**

```./iOSAssetExtractor -i /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk -o /Users/bmcquilkin/Desktop/ExportOSX -g 1```

Project Notes:
--------

* The car extractor needed to be placed in a separate executable. CoreUI seems to check if the current process has already loaded an "Assets.car" file, and if it has it throws a EXC_BAD_ACCESS exception. The way I found to get around it is to spawn a new extraction process for each car file we need to export. And to do that, I needed to create a separate exceutable that only extracted a single car file, and run the car extractor through NSTask as a separate process.

    There is probably a way to completely remove the evidence that a given process already loaded a car file, but this seems like an easier solution.

Contact Me:
-------------
If you have any questions comments or suggestions, send me a message. If you find a bug, or want to submit a pull request, let me know.

License:
--------
MIT License

> Copyright (c) 2016 Brandon McQuilkin
> 
> Permission is hereby granted, free of charge, to any person obtaining 
>a copy of this software and associated documentation files (the  
>"Software"), to deal in the Software without restriction, including 
>without limitation the rights to use, copy, modify, merge, publish, 
>distribute, sublicense, and/or sell copies of the Software, and to 
>permit persons to whom the Software is furnished to do so, subject to  
>the following conditions:
> 
> The above copyright notice and this permission notice shall be 
>included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
>EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
>MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
>IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
>CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
>TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
>SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
