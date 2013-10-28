//
//  GeoserverSettings.m
//  GeoServer
//
//  Created by Michael Weisman on 10/8/2013.
// Copyright (c) 2013 Boundless (http://boundlessgeo.com/)
//
//

#import "GeoserverSettings.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation GeoserverSettings

+ (GeoserverSettings *)sharedSettings
{
    static GeoserverSettings *_sharedSettings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSettings = [[GeoserverSettings alloc] init];
        NSString *iniPath;
        NSString *defaultIniPath = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"jetty"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:defaultIniPath]) {
            iniPath = defaultIniPath;
        } else {
            // Very likely that initial setup has not run. Use default values.
            iniPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"jetty"];
        }
        
        // Figure out the port and data_dir location
        NSString *jettyIniPath = [NSString pathWithComponents:@[iniPath, @"start.ini"]];
        NSError *iniReadErr;
        NSString *jettyIni = [NSString stringWithContentsOfFile:jettyIniPath encoding:NSUTF8StringEncoding error:&iniReadErr];
        if (!iniReadErr) {
            for (NSString *line in [jettyIni componentsSeparatedByString:@"\n"]) {
                NSArray *lineComponents = [line componentsSeparatedByString:@"="];
                if ([[lineComponents objectAtIndex:0] isEqualToString:@"-Djetty.port"]) {
                    _sharedSettings.jettyPort = [[lineComponents lastObject] integerValue];
                } else if ([[lineComponents objectAtIndex:0] isEqualToString:@"-DGEOSERVER_DATA_DIR"]) {
                    _sharedSettings.dataDir = [lineComponents lastObject];
                }
            }
        } else {
            NSLog(@"Error reading start.ini. Using port 8080");
            _sharedSettings.jettyPort = 8080;
        }
        
        if (!_sharedSettings.dataDir) {
            // Data Dir isn't set in ini. Set it to the default value.
            _sharedSettings.dataDir = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"data_dir"];
        }
        
        // Figure out the other vars from suite ini which is a real ini file
        NSString *suiteIniPath = [NSString pathWithComponents:@[iniPath, @"version.ini"]];
        dictionary *suiteIni = iniparser_load([suiteIniPath UTF8String]);
        _sharedSettings.suiteVersion = [NSString stringWithUTF8String:iniparser_getstring(suiteIni, ":suite_version", NULL)];
        _sharedSettings.suiteRev = [NSString stringWithUTF8String:iniparser_getstring(suiteIni, ":build_revision", NULL)];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        _sharedSettings.suiteBuildDate = [df dateFromString:[NSString stringWithUTF8String: iniparser_getstring(suiteIni, ":build_prettydate", NULL)]];
 
        iniparser_freedict(suiteIni);
    });
    
    return _sharedSettings;
}

@end
