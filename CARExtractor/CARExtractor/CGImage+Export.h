//
//  CGImage+Export.h
//  CARExtractor
//
//  Created by McQuilkin, Brandon on 2/3/16.
//  Copyright © 2016 BrandonMcQuilkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

void CGImageWriteToFile(CGImageRef image, NSString *path)
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path.stringByDeletingLastPathComponent])
        [[NSFileManager defaultManager] createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:true attributes:nil error:nil];
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
}
