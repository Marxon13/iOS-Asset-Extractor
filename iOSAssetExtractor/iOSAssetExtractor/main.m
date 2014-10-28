//
//  main.m
//  iOSAssetExtractor
//
/*Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

#pragma mark Naming

NSString *outputPathForFile(NSString *fileDirectory, NSString *exportPath, BOOL group)
{
    if (!group) {
        //Just place the file in the root of the output folder.
        return exportPath;
    } else {
        return [NSString stringWithFormat:@"%@-%@", [exportPath stringByAppendingPathComponent:fileDirectory.lastPathComponent.stringByDeletingPathExtension], fileDirectory.pathExtension];
    }
}

#pragma mark Copying

#pragma mark Copying

void copyFileAtPath(NSString *path, NSString* exportLocation, BOOL group)
{
    //-----------------------------------------------
    //Notify that we are processing an image
    //-----------------------------------------------
    NSLog(@"    Moving file: %@%@", path.stringByDeletingLastPathComponent.lastPathComponent, path.lastPathComponent);
    
    //Get the output file path
    NSString *ouputPath = [outputPathForFile(path.stringByDeletingLastPathComponent, exportLocation, group) stringByAppendingPathComponent:path.lastPathComponent];
    //Create the intermediate directories if necessary
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:ouputPath.stringByDeletingLastPathComponent withIntermediateDirectories:true attributes:nil error:&error];
    
    if (error) {
        NSLog(@"    An Error Occured: %@", error.localizedDescription);
    }
    
    if (!error) {
        error = nil;
        //Copy the file
        [[NSFileManager defaultManager] copyItemAtPath:path toPath:ouputPath error:&error];
        
        if (error && [error.localizedDescription rangeOfString:@"already exists"].location == NSNotFound) {
            NSLog(@"    An Error Occured: %@", error.localizedDescription);
        }
    }
}

#pragma mark Processing

int export(NSString *path, NSString *outputDirectoryPath, BOOL group, BOOL exportPDF, BOOL exportPNG, BOOL exportCAR)
{
    //-----------------------------------------------
    //Notify that we will begin searching for files
    //-----------------------------------------------
    
    NSLog(@"Searching for files...");
    
    //Setup the directory enumerator
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    NSMutableArray *validFiles;
    if (exists && !isDirectory) {
        //Only have to extract one file
        validFiles = [@[path] mutableCopy];
        
    } else if (exists && isDirectory) {
        //Search for files to extract.
        NSURL *searchURL = [NSURL fileURLWithPath:path];
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:searchURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error) {
            NSLog(@"    An Error Occured: %@", error.localizedDescription);
            return true;
        }];
        
        //Do we have a valid enumerator
        if (!enumerator) {
            NSLog(@"    Failure: Unable to enumerate file structure.");
            return 1;
        }
        
        //Loop through the enumerator, and collect all the valid files.
        validFiles = [NSMutableArray array];
        for (NSURL *url in enumerator) {
            NSError *error;
            NSNumber *isDirectory;
            
            if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                //Handle error
                NSLog(@"    An Error Occured: %@", error.localizedDescription);
                
            } else if (![isDirectory boolValue]) {
                //Is it a valid file type?
                if ([url.pathExtension.uppercaseString isEqualToString:@"PNG"] || [url.pathExtension.uppercaseString isEqualToString:@"PNG"] || [url.pathExtension.uppercaseString isEqualToString:@"CAR"]) {
                    [validFiles addObject:url.path];
                }
            }
        }
    }
    
    //-----------------------------------------------
    //Notify that we are finished searching for files
    //-----------------------------------------------
    
    NSLog(@"Finished searching for files...");
    
    //Enumerate over all the files
    NSUInteger index = 1;
    NSUInteger count = validFiles.count;
    
    for (NSString *path in validFiles) {
        
        //-----------------------------------------------
        //Notify that we are processing a file
        //-----------------------------------------------
        
        index ++;
        
        //We have a file!
        
        //Is this a file type we should process?
        NSString *extension = path.lastPathComponent.pathExtension;
        
        if ([extension.uppercaseString isEqualToString:@"CAR"] && exportCAR) {
            NSLog(@"Processing file: %li/%li, %@", index, count, path);
            //Extract the CAR file, access the car exceutable, and run that. We need to run it as a separate process since CoreUI seems to only allow loading of one asset catalouge per process. When a process tries to load a second, a bad access exception occurs.
            NSString *carExtractorLocation = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"CARExtractor"];
            
            //Create the task to run the process
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:carExtractorLocation];
            
            NSArray *arguments = @[@"-i", path, @"-o", outputPathForFile(path.stringByDeletingLastPathComponent, outputDirectoryPath, group)];
            [task setArguments:arguments];
            
            //Handle output
            NSPipe *pipe = [[NSPipe alloc] init];
            task.standardOutput = pipe;
            
            [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
            [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification){
                NSData *output = [[pipe fileHandleForReading] availableData];
                NSString *outString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
                NSLog(@"%@", outString);
                [[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
            }];
            
            //Run the task
            [task launch];
            [task waitUntilExit];
            
            [[NSNotificationCenter defaultCenter] removeObserver:nil name:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading]];
            
            continue;
        }
        
        if ([extension.uppercaseString isEqualToString:@"PDF"] && exportPDF) {
            NSLog(@"Processing file: %li/%li, %@", index, count, path);
            //Extract the PDF file
            copyFileAtPath(path, outputDirectoryPath, group);
            continue;
        }
        
        if ([extension.uppercaseString isEqualToString:@"PNG"] && exportPNG) {
            NSLog(@"Processing file: %li/%li, %@", index, count, path);
            //Extract the PNG file
            copyFileAtPath(path, outputDirectoryPath, group);
            continue;
        }
    }
    
    return 0;
}

#pragma mark Main

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        //Gather inputs
        
        NSString *inputPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"i"].stringByExpandingTildeInPath;
        NSString *outputPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"o"].stringByExpandingTildeInPath;
        
        if (!inputPath || !outputPath) {
            NSLog(@"Please make sure to specify input and output paths.");
            return 1;
        }
        
        BOOL group = false;
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"g"]) {
            group = true;
        }
        
        BOOL exportPDF = true;
        BOOL exportPNG = true;
        BOOL exportCAR = true;
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"t"]) {
            exportPDF = false;
            exportPNG = false;
            exportCAR = false;
            
            NSArray *allowedTypes = [[[[NSUserDefaults standardUserDefaults] stringForKey:@"t"].uppercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@","];
            
            for (NSString *type in allowedTypes) {
                if ([type isEqualToString:@"PDF"]) {
                    exportPDF = true;
                }
                if ([type isEqualToString:@"PNG"]) {
                    exportPNG = true;
                }
                if ([type isEqualToString:@"CAR"]) {
                    exportCAR = true;
                }
            }
        }
        
        export(inputPath, outputPath, group, exportPDF, exportPNG, exportCAR);
    }
    return 0;
}
