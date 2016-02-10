//
//  CARExporter.h
//  CARExtractor
//
//  Created by McQuilkin, Brandon on 2/9/16.
//  Copyright © 2016 BrandonMcQuilkin. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CUICatalog, CUICommonAssetStorage;

@interface CARExporter : NSObject

- (instancetype)initWithCatalog:(CUICatalog *)catalog storage:(CUICommonAssetStorage *)storage;
- (void)exportToDirectory:(NSString *)outputDirectory;

@property (nonatomic, assign) BOOL exportUnslicedImages;
@property (nonatomic, assign) BOOL exportPDFs;
@property (nonatomic, assign) BOOL exportImages;
@property (nonatomic, assign) BOOL exportLinkDestinations;

@end
