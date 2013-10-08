//
//  GeoserverSettings.h
//  GeoServer
//
//  Created by Michael Weisman on 10/8/2013.
// Copyright (c) 2013 Boundless (http://boundlessgeo.com/)
//
//

#import <Foundation/Foundation.h>
#import "iniparser.h"

@interface GeoserverSettings : NSObject

@property NSString *suiteVersion;
@property NSString *suiteRev;
@property NSDate *suiteBuildDate;
@property NSUInteger jettyPort;
@property NSString *dataDir;

+ (GeoserverSettings *)sharedSettings;

@end
