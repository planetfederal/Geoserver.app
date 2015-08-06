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
        NSString *bundleIniPath;
        BOOL signedIni = NO;
        BOOL unsignedIni = NO;

        NSString *signedSuiteIniPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Containers/com.boundlessgeo.geoserver/Data/Library/Application Support/GeoServer/jetty"];
        NSString *unsignedSuiteIniPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/GeoServer/jetty"];
        NSString *defaultIniPath = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"jetty"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:signedSuiteIniPath]) {
            // Search for signed install first
            signedIni = YES;
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:unsignedSuiteIniPath]) {
            // Search for expected ini
            unsignedIni = YES;
        }
        if (!signedIni && !unsignedIni){
            // Very likely that initial setup has not run. Use default values.
            bundleIniPath = [[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"jetty"] stringByResolvingSymlinksInPath];
        }
        
        // Determine which ini to use
        if (signedIni && unsignedIni) {
            // ignore any version -suffix, e.g. 4.6.1-SNAPSHOT or 4.7-b3, by using NSString's componentsSeparatedByCharactersInSet
            NSString *signedSettings = [NSString pathWithComponents:@[signedSuiteIniPath, @"version.ini"]];
            dictionary *signedIni = iniparser_load([signedSettings UTF8String]);
            NSArray *signedSuiteVer = [[NSString stringWithUTF8String:iniparser_getstring(signedIni, ":suite_version", "")] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".-"]];
            iniparser_freedict(signedIni);
            
            NSString *unsignedSettings = [NSString pathWithComponents:@[unsignedSuiteIniPath, @"version.ini"]];
            dictionary *unsignedIni = iniparser_load([unsignedSettings UTF8String]);
            NSArray *unsignedSuiteVer = [[NSString stringWithUTF8String:iniparser_getstring(unsignedIni, ":suite_version", "")] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".-"]];
            iniparser_freedict(unsignedIni);
#if DEBUG
            NSLog(@"signedSuiteVer: %@", [signedSuiteVer description]);
            NSLog(@"unsignedSuiteVer: %@", [unsignedSuiteVer description]);
#endif
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            
            if ([f numberFromString:[signedSuiteVer objectAtIndex:0]] >= [f numberFromString:[unsignedSuiteVer objectAtIndex:0]]
                &&
                [f numberFromString:[signedSuiteVer objectAtIndex:1]] > [f numberFromString:[unsignedSuiteVer objectAtIndex:1]]) {
                iniPath = signedSuiteIniPath;
            } else {
                iniPath = unsignedSuiteIniPath;
            }
        } else if (signedIni && !unsignedIni) {
            iniPath = signedSuiteIniPath;
        } else if (!signedIni && unsignedIni) {
            iniPath = unsignedSuiteIniPath;
        } else {
            iniPath = bundleIniPath;
        }
#if DEBUG
        NSLog(@"signedSuiteIniPath: %@", signedSuiteIniPath);
        NSLog(@"unsignedSuiteIniPath: %@", unsignedSuiteIniPath);
        NSLog(@"defaultIniPath: %@", defaultIniPath);
        NSLog(@"iniPath: %@", iniPath);
#endif
        
        if ([defaultIniPath compare:iniPath] != 0) {
            // Looks like a mismatch in gs dirs. Copy to data correct place.
            NSError *moveErr;
            
            NSString *oldDataDir = [[defaultIniPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"data_dir"];
            NSString *oldJettyDir = [[defaultIniPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/jetty"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:oldDataDir]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yMMdHHmm"];
                NSString *dataBkgPath = [NSString stringWithFormat:@"%@_%@",oldDataDir,[formatter stringFromDate:[NSDate date]]];
                [[NSFileManager defaultManager] moveItemAtPath:oldDataDir toPath:dataBkgPath error:&moveErr];
                if (moveErr) {
                    NSLog(@"GeoServer upgrade error: %@", moveErr.localizedDescription);
                    NSAlert *upgradeFailAlert = [NSAlert alertWithMessageText:@"Error upgrading Suite" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"%@. Please manually delete %@", moveErr.localizedDescription, oldDataDir]];
                    [upgradeFailAlert runModal];
                }
            }
            
            moveErr = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:oldJettyDir]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yMMdHHmm"];
                NSString *jettyBkgPath = [NSString stringWithFormat:@"%@_%@",oldJettyDir,[formatter stringFromDate:[NSDate date]]];
                [[NSFileManager defaultManager] moveItemAtPath:oldJettyDir toPath:jettyBkgPath error:&moveErr];
                if (moveErr) {
                    NSLog(@"GeoServer upgrade error: %@", moveErr.localizedDescription);
                    NSAlert *upgradeFailAlert = [NSAlert alertWithMessageText:@"Error upgrading Suite" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"%@. Please manually delete %@", moveErr.localizedDescription, oldJettyDir]];
                    [upgradeFailAlert runModal];
                }
            }
            
            moveErr = nil;
            NSString *newDataDir = [[iniPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"data_dir"];
            if (!signedIni && !unsignedIni) {
                // clean install; data_dir is subdirectory of default 'jetty' in app bundle
                newDataDir = [iniPath stringByAppendingPathComponent:@"data_dir"];
            }
            NSString *newJettyDir = [[iniPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"jetty"];
            [[NSFileManager defaultManager] copyItemAtPath:newDataDir toPath:[[defaultIniPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"data_dir"] error:&moveErr];
            if (moveErr) {
                NSLog(@"GeoServer upgrade error: %@", moveErr.localizedDescription);
                NSAlert *upgradeFailAlert = [NSAlert alertWithMessageText:@"Error upgrading Suite" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"%@. Please manually delete %@", moveErr.localizedDescription, iniPath]];
                [upgradeFailAlert runModal];
            }
            
            moveErr = nil;
            [[NSFileManager defaultManager] copyItemAtPath:newJettyDir toPath:defaultIniPath error:&moveErr];
            if (moveErr) {
                NSLog(@"GeoServer upgrade error: %@", moveErr.localizedDescription);
                NSAlert *upgradeFailAlert = [NSAlert alertWithMessageText:@"Error upgrading Suite" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"%@. Please manually delete %@", moveErr.localizedDescription, iniPath]];
                [upgradeFailAlert runModal];
            }
            
            // set iniPath to default location
            iniPath = defaultIniPath;
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
        _sharedSettings.suiteVersion = [NSString stringWithUTF8String:iniparser_getstring(suiteIni, ":suite_version", "")];
        _sharedSettings.suiteRev = [NSString stringWithUTF8String:iniparser_getstring(suiteIni, ":build_revision", "unknown_rev")];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        _sharedSettings.suiteBuildDate = [df dateFromString:[NSString stringWithUTF8String: iniparser_getstring(suiteIni, ":build_prettydate", "")]];
 
        iniparser_freedict(suiteIni);
    });

    return _sharedSettings;
}

@end
