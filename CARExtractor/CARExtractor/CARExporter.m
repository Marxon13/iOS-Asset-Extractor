//
//  CARExporter.m
//  CARExtractor
//
//  Created by McQuilkin, Brandon on 2/9/16.
//  Copyright © 2016 BrandonMcQuilkin. All rights reserved.
//

#import "CARExporter.h"
#import "CoreUI.h"
#import <CoreGraphics/CoreGraphics.h>
#import "CGImage+Export.h"
#import <objc/runtime.h>

@implementation CARExporter {
    CUICatalog *_catalog;
    CUICommonAssetStorage *_storage;
    NSString *_outputDirectory;
}

- (instancetype)initWithCatalog:(CUICatalog *)catalog storage:(CUICommonAssetStorage *)storage {
    _catalog = catalog;
    _storage = storage;
    
    _exportImages = true;
    _exportPDFs = true;
    _exportUnslicedImages = false;
    _exportLinkDestinations = true;
    
    return self;
}

- (void)exportToDirectory:(NSString *)outputDirectory {
    _outputDirectory = outputDirectory;
    
    // Avoid naming collisions.
    NSMutableDictionary *names = @{}.mutableCopy;
    
    for (CUIRenditionKey *aKey in _storage.allAssetKeys) {
        // Get the rendition for the given key.
        const struct _renditionkeytoken *token = aKey.keyList;
        CUIThemeRendition *rendition = [[_catalog _themeStore] renditionWithKey:token];
        
        NSString *name = rendition.name;
        if (names[name] != nil) {
            NSUInteger count = ((NSNumber *)names[name]).unsignedIntegerValue;
            count += 1;
            names[name] = [NSNumber numberWithUnsignedInteger:count];
            name = [name stringByAppendingFormat:@"%li", count];
        } else {
            names[name] = [NSNumber numberWithUnsignedInteger:1];
        }
        
        // Export
        [self exportThemeRendition:rendition fileName:name];
    }
    
    if (_exportImages) {
        for (NSString *name in [[_catalog _themeStore] allImageNames]) {
            NSArray *images = [[_catalog _themeStore] imagesWithName: name];
            for (CUINamedLookup *lookup in images) {
                if ([[lookup class] isSubclassOfClass:[CUINamedImage class]]) {
                    CUINamedImage *asset = (CUINamedImage *)lookup;
                    NSString *fileName = [name stringByAppendingFormat:@"_%lix%li_@%lix.png", (NSUInteger)asset.size.width, (NSUInteger)asset.size.height, (NSUInteger)asset.scale];
                    NSLog(@"    %@ -> IMAGE", fileName);
                    CGImageRef image = asset.image;
                    CGImageWriteToFile(image, [outputDirectory stringByAppendingPathComponent:fileName]);
                } else if ([[lookup class] isSubclassOfClass:[CUINamedImage class]]) {
                    // No need to load. The indivual images get picked up separatly with the proper path. The layers are always nil anyway.
                }
            }
            
        }
    }
}

- (void)exportThemeRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    // Set the file name if necessary
    if (fileName == nil) {
        fileName = rendition.name;
    }
    
    // Export the type
    if ([[rendition class] isSubclassOfClass:NSClassFromString(@"_CUIPDFRendition")]) {
        if (_exportPDFs) {
            [self exportPDFRendition:rendition fileName:fileName];
        }
    } else if ([[rendition class] isSubclassOfClass:NSClassFromString(@"_CUIThemePixelRendition")]) {
        if (_exportUnslicedImages) {
            [self exportUnslicedThemePixelRendition:rendition fileName:fileName];
        }
        if (_exportImages) {
            [self exportSlicedThemePixelRendition:rendition fileName:fileName];
        }
    } else if ([[rendition class] isSubclassOfClass:NSClassFromString(@"_CUIInternalLinkRendition")]) {
        if (_exportLinkDestinations) {
            // Get the linked asset
            _CUIInternalLinkRendition *link = (_CUIInternalLinkRendition *)rendition;
            CUIRenditionKey *linkedRenditionKey = link.linkingToRendition;
            const struct _renditionkeytoken *linkedToken = linkedRenditionKey.keyList;
            CUIThemeRendition *linkedRendition = [[_catalog _themeStore] renditionWithKey:linkedToken];
            //Export
            [self exportThemeRendition:linkedRendition fileName:fileName];
        }
    } else if ([[rendition class] isSubclassOfClass:NSClassFromString(@"_CUIRawPixelRendition")]) {
        if (_exportUnslicedImages) {
            [self exportUnslicedRawPixelRendition:rendition fileName:fileName];
        }
        if (_exportImages) {
            [self exportSlicedRawPixelRendition:rendition fileName:fileName];
        }
    } else if ([[rendition class] isSubclassOfClass:NSClassFromString(@"_CUILayerStackRendition")]) {
        [self exportLayerStackRendition:rendition fileName:fileName];
    } else {
        NSLog(@"    UNKNOWN: %@", rendition);
    }
}

- (void)exportPDFRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    NSLog(@"    %@ -> PDF", fileName);
    
    // Retreive the document.
    _CUIPDFRendition *pdf = (_CUIPDFRendition *)rendition;
    CGPDFDocumentRef doc = pdf.pdfDocument;
    
    // Render to file.
    if (![[fileName pathExtension].lowercaseString isEqualToString:@"pdf"]) {
        fileName = [fileName stringByAppendingPathExtension:@"pdf"];
    }
    
    // Create directory if necessary
    if (![[NSFileManager defaultManager] fileExistsAtPath:[_outputDirectory stringByAppendingPathComponent:fileName].stringByDeletingLastPathComponent])
        [[NSFileManager defaultManager] createDirectoryAtPath:[_outputDirectory stringByAppendingPathComponent:fileName].stringByDeletingLastPathComponent withIntermediateDirectories:true attributes:nil error:nil];
    
    // Export
    NSURL *url = [NSURL fileURLWithPath:[_outputDirectory stringByAppendingPathComponent:fileName]];
    CGContextRef writeContext = CGPDFContextCreateWithURL((CFURLRef)url, NULL, NULL);
    for (int i = 1; i <= CGPDFDocumentGetNumberOfPages(doc); i++) {
        CGPDFPageRef page = CGPDFDocumentGetPage(doc, i);
        CGRect mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        CGContextBeginPage(writeContext, &mediaBox);
        CGContextDrawPDFPage(writeContext, page);
        CGContextEndPage(writeContext);
    }
    
    // Save
    CGPDFContextClose(writeContext);
}

- (void)exportUnslicedThemePixelRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    NSLog(@"    %@ -> UNSLICED IMAGE", fileName);
    // Retreive the image
    _CUIThemePixelRendition *pixel = (_CUIThemePixelRendition *)rendition;
    
    CGImageRef image = [pixel unslicedImage];
    
    // Add unsliced to name
    if ([[fileName pathExtension].lowercaseString isEqualToString:@"png"]) {
        fileName = [fileName stringByDeletingPathExtension];
    }
    fileName = [fileName stringByAppendingString:@"_unsliced.png"];
    
    CGImageWriteToFile(image, [_outputDirectory stringByAppendingPathComponent:fileName]);
}

- (void)exportSlicedThemePixelRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    //NSLog(@"    %@ -> IMAGE", fileName);
    // Retreive the image
    //_CUIThemePixelRendition *pixel = (_CUIThemePixelRendition *)rendition;
    // TODO: I would rather export images this way, but there is no way to get the sliceing information.
}

- (void)exportSlicedRawPixelRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    // TODO: Need to retreive sliced image here.
    [self exportUnslicedRawPixelRendition:rendition fileName:fileName];
}

- (void)exportUnslicedRawPixelRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    NSLog(@"    %@ -> UNSLICED RAW IMAGE", fileName);
    // Retreive the image
    _CUIRawPixelRendition *pixel = (_CUIRawPixelRendition *)rendition;
    
    CGImageRef image = [pixel unslicedImage];
    
    // Add unsliced to name
    if ([[fileName pathExtension].lowercaseString isEqualToString:@"png"]) {
        fileName = [fileName stringByDeletingPathExtension];
    }
    fileName = [fileName stringByAppendingString:@"_unsliced.png"];
    
    CGImageWriteToFile(image, [_outputDirectory stringByAppendingPathComponent:fileName]);
}

- (void)exportLayerStackRendition:(CUIThemeRendition *)rendition fileName:(NSString *)fileName {
    NSLog(@"    %@ -> LAYER STACK", fileName);
    // Retreive the image
    _CUILayerStackRendition *layerStack = (_CUILayerStackRendition *)rendition;
    for (CUIRenditionLayerReference *layerRef in [layerStack layerReferences]) {
        CUIRenditionKey *layerKey = [layerRef referenceKey];
        const struct _renditionkeytoken *layerToken = layerKey.keyList;
        CUIThemeRendition *layerRendition = [[_catalog _themeStore] renditionWithKey:layerToken];
        // TODO: Layer rendition is nil. Why?
    }
}

@end
