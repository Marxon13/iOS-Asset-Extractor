//
//  main.m
//  CARExtractor
//
//  Created by Brandon McQuilkin on 10/27/14.
//
//  Based on  by cartool Steven Troughton-Smith on 14/07/2013.
//  Copyright (c) 2013 High Caffeine Content. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma Private Frameworks

@interface CUICommonAssetStorage : NSObject

-(NSArray *)allAssetKeys;
-(NSArray *)allRenditionNames;

-(id)initWithPath:(NSString *)p;

-(NSString *)versionString;

@end

@interface CUINamedImage : NSObject

-(CGImageRef)image;

@end

@interface CUIRenditionKey : NSObject

+ (id)renditionKeyWithKeyList:(const struct _renditionkeytoken { unsigned short x1; unsigned short x2; }*)arg1;
+ (id)_placeHolderKey;
+ (id)renditionKey;
+ (void)initialize;

- (id)descriptionBasedOnKeyFormat:(const struct _renditionkeyfmt { unsigned int x1; unsigned int x2; unsigned int x3; unsigned int x4[0]; }*)arg1;
- (void)setThemeIdentifier:(long long)arg1;
- (long long)themeGraphicsClass;
- (void)setThemeGraphicsClass:(long long)arg1;
- (long long)themeMemoryClass;
- (void)setThemeMemoryClass:(long long)arg1;
- (void)setThemeSizeClassVertical:(long long)arg1;
- (void)setThemeSizeClassHorizontal:(long long)arg1;
- (void)setThemeSubtype:(long long)arg1;
- (void)setThemeIdiom:(long long)arg1;
- (long long)themePresentationState;
- (void)setThemePresentationState:(long long)arg1;
- (long long)themePreviousState;
- (void)setThemePreviousState:(long long)arg1;
- (long long)themeDimension2;
- (void)setThemeDimension2:(long long)arg1;
- (long long)themeDimension1;
- (void)setThemeDimension1:(long long)arg1;
- (long long)themePreviousValue;
- (void)setThemePreviousValue:(long long)arg1;
- (long long)themeDirection;
- (void)setThemeDirection:(long long)arg1;
- (void)setThemePart:(long long)arg1;
- (void)setThemeElement:(long long)arg1;
- (void)removeValueForKeyTokenIdentifier:(long long)arg1;
- (id)nameOfAttributeName:(int)arg1;
- (long long)themeSubtype;
- (long long)themeIdiom;
- (long long)themeSizeClassVertical;
- (long long)themeSizeClassHorizontal;
- (long long)themeIdentifier;
- (long long)themePart;
- (long long)themeElement;
- (unsigned short)_systemTokenCount;
- (void)_expandKeyIfNecessaryForCount:(long long)arg1;
- (void)setThemeValue:(long long)arg1;
- (void)setThemeState:(long long)arg1;
- (void)setThemeSize:(long long)arg1;
- (long long)themeScale;
- (long long)themeSize;
- (long long)themeValue;
- (long long)themeState;
- (void)setValuesFromKeyList:(const struct _renditionkeytoken { unsigned short x1; unsigned short x2; }*)arg1;
- (void)copyValuesFromKeyList:(const struct _renditionkeytoken { unsigned short x1; unsigned short x2; }*)arg1;
- (long long)themeLayer;
- (void)setThemeLayer:(long long)arg1;
- (void)setThemeScale:(long long)arg1;
- (id)initWithKeyList:(const struct _renditionkeytoken { unsigned short x1; unsigned short x2; }*)arg1;
- (const struct _renditionkeytoken { unsigned short x1; unsigned short x2; }*)keyList;
- (id)initWithThemeElement:(long long)arg1 themePart:(long long)arg2 themeSize:(long long)arg3 themeDirection:(long long)arg4 themeValue:(long long)arg5 themeDimension1:(long long)arg6 themeDimension2:(long long)arg7 themeState:(long long)arg8 themePresentationState:(long long)arg9 themeLayer:(long long)arg10 themeScale:(long long)arg11 themeIdentifier:(long long)arg12;
- (id)init;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (void)dealloc;
- (id)description;
- (id)copyWithZone:(struct _NSZone { }*)arg1;

@end

@interface CUIThemeFacet : NSObject

+(CUIThemeFacet *)themeWithContentsOfURL:(NSURL *)u error:(NSError **)e;
+ (void)_invalidateArtworkCaches;

@end

@interface CUICatalog : NSObject

-(id)initWithName:(NSString *)n fromBundle:(NSBundle *)b;
-(id)allKeys;
-(CUINamedImage *)imageWithName:(NSString *)n scaleFactor:(CGFloat)s;
-(CUINamedImage *)imageWithName:(NSString *)n scaleFactor:(CGFloat)s deviceIdiom:(int)idiom;

@end

#define kCoreThemeIdiomPhone 1
#define kCoreThemeIdiomPad 2

#pragma mark Export Image

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

#pragma mark Export CAR

void exportCarFileAtPath(NSString * carPath, NSString *outputDirectoryPath)
{
    NSError *error = nil;
    
    CUIThemeFacet *facet = [CUIThemeFacet themeWithContentsOfURL:[NSURL fileURLWithPath:carPath] error:&error];
    CUICatalog *catalog = [[CUICatalog alloc] init];
    /* Override CUICatalog to point to a file rather than a bundle */
    [catalog setValue:facet forKey:@"_storageRef"];
    /* CUICommonAssetStorage won't link */
    CUICommonAssetStorage *storage = [[NSClassFromString(@"CUICommonAssetStorage") alloc] initWithPath:carPath];
    
    for (NSString *key in [storage allRenditionNames])
    {
        NSLog(@"    Writing Image: %@", key);
        
        CGImageRef iphone1X = [[catalog imageWithName:key scaleFactor:1.0 deviceIdiom:kCoreThemeIdiomPhone] image];
        CGImageRef iphone2X = [[catalog imageWithName:key scaleFactor:2.0 deviceIdiom:kCoreThemeIdiomPhone] image];
        CGImageRef iphone3X = [[catalog imageWithName:key scaleFactor:3.0 deviceIdiom:kCoreThemeIdiomPhone] image];
        CGImageRef ipad1X = [[catalog imageWithName:key scaleFactor:1.0 deviceIdiom:kCoreThemeIdiomPad] image];
        CGImageRef ipad2X = [[catalog imageWithName:key scaleFactor:2.0 deviceIdiom:kCoreThemeIdiomPad] image];
        
        if (iphone1X) {
            NSLog(@"        Writing ~iPhone@1x");
            CGImageWriteToFile(iphone1X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@~iphone.png", key]]);
        } else {
            NSLog(@"        ~iPhone@1x does not exist");
        }
        
        if (iphone2X) {
            if (iphone2X != iphone1X || !iphone1X) {
                NSLog(@"        Writing ~iPhone@2x");
                CGImageWriteToFile(iphone2X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@~iphone@2x.png", key]]);
            } else {
                NSLog(@"        ~iPhone@2x is the same as ~iPhone@1x");
            }
        } else {
            NSLog(@"        ~iPhone@2x does not exist");
        }
        
        if (iphone3X) {
            if (iphone3X != iphone2X || !iphone2X) {
                NSLog(@"        Writing ~iPhone@3x");
                CGImageWriteToFile(iphone3X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@~iphone@3x.png", key]]);
            } else {
                NSLog(@"        ~iPhone@3x is the same as ~iPhone@2x");
            }
        } else {
            NSLog(@"        ~iPhone@3x does not exist");
        }
        
        if (ipad1X) {
            if (ipad1X != iphone1X || !iphone1X) {
                NSLog(@"        Writing ~iPad@1x");
                CGImageWriteToFile(ipad1X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@~ipad.png", key]]);
            } else {
                NSLog(@"        ~iPad@1x is the same as ~iPhone@1x");
            }
        } else {
            NSLog(@"        ~iPad@1x does not exist");
        }
        
        if (ipad2X) {
            if (ipad2X != iphone2X || !iphone2X) {
                NSLog(@"        Writing ~iPad@2x");
                CGImageWriteToFile(ipad2X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@~ipad@2x.png", key]]);
            } else {
                NSLog(@"        ~iPad@2x is the same as ~iPhone@2x");
            }
        } else {
            NSLog(@"        ~iPad@2x does not exist");
        }
     
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        //Check inputs
        NSString *input = [[NSUserDefaults standardUserDefaults] stringForKey:@"i"];
        NSString *output = [[NSUserDefaults standardUserDefaults] stringForKey:@"o"];
        
        if (!input || !output) {
            NSLog(@"Invalid call, missing input or output.");
            return 1;
        }
        
        exportCarFileAtPath(input, output);
    }
    return 0;
}
