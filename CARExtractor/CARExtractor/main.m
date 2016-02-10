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
#import "CoreUI.h"
#import "CARExporter.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        //Check inputs
        NSString *input = [[NSUserDefaults standardUserDefaults] stringForKey:@"i"];
        NSString *output = [[NSUserDefaults standardUserDefaults] stringForKey:@"o"];
        
        if (!input || !output) {
            NSLog(@"Invalid call, missing input or output.");
            return 1;
        }
        
        NSError *error = nil;
        
        CUIThemeFacet *facet = [CUIThemeFacet themeWithContentsOfURL:[NSURL fileURLWithPath:input] error:&error];
        CUICatalog *catalog = [[CUICatalog alloc] init];
        /* Override CUICatalog to point to a file rather than a bundle */
        [catalog setValue:facet forKey:@"_storageRef"];
        /* CUICommonAssetStorage won't link */
        CUICommonAssetStorage *storage = [[NSClassFromString(@"CUICommonAssetStorage") alloc] initWithPath:input];
        
        if (catalog == nil || storage == nil) {
            NSLog(@"Unable to load asset catalog.");
            return 1;
        }
        
        CARExporter *exporter = [[CARExporter alloc] initWithCatalog:catalog storage:storage];
        
        [exporter exportToDirectory:output];
        
    }
    return 0;
}

