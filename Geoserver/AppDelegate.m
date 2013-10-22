// AppDelegate.m
//
// Created by Mattt Thompson (http://mattt.me/)
// Copyright (c) 2012 Heroku (http://heroku.com/)
// 
// Portions Copyright (c) 1996-2012, The PostgreSQL Global Development Group
// Portions Copyright (c) 1994, The Regents of the University of California
//
// Permission to use, copy, modify, and distribute this software and its
// documentation for any purpose, without fee, and without a written agreement
// is hereby granted, provided that the above copyright notice and this
// paragraph and the following two paragraphs appear in all copies.
//
// IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
// LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
// EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//
// THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN
// "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
// PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

#import <ServiceManagement/ServiceManagement.h>
#import "AppDelegate.h"
#import "GeoserverServer.h"
#import "GeoserverStatusMenuItemViewController.h"
#import "WelcomeWindowController.h"
#import "NSFileManager+DirectoryLocations.h"
#import "GeoserverSettings.h"

static BOOL GeoserverIsHelperApplicationSetAsLoginItem() {
    BOOL flag = NO;
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    for (NSDictionary *job in jobs) {
        if ([[job valueForKey:@"Label"] isEqualToString:@"com.boundlessgeo.GeoserverHelper"]) {
            flag = YES;
        }
    }
    
    CFRelease((__bridge CFMutableArrayRef)jobs);
    
    return flag;
}

@implementation AppDelegate {
    NSStatusItem *_statusBarItem;
    WelcomeWindowController *_welcomeWindowController;    
}
@synthesize geoserverStatusMenuItemViewController = _geoserverStatusMenuItemViewController;
@synthesize statusBarMenu = _statusBarMenu;
@synthesize geoserverStatusMenuItem = _geoserverStatusMenuItem;
@synthesize automaticallyStartMenuItem = _automaticallyStartMenuItem;
@synthesize openGeoServerMenuItem = _openGeoServerMenuItem;

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    _statusBarItem.highlightMode = YES;
    _statusBarItem.menu = self.statusBarMenu;
    _statusBarItem.image = [NSImage imageNamed:@"status-off"];
    _statusBarItem.alternateImage = [NSImage imageNamed:@"status-on"];
        
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kGeoserverAutomaticallyOpenDocumentationPreferenceKey]];
    [self.automaticallyStartMenuItem setState:GeoserverIsHelperApplicationSetAsLoginItem() ? NSOnState : NSOffState];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kGeoserverFirstLaunchPreferenceKey]) {
        _welcomeWindowController = [[WelcomeWindowController alloc] initWithWindowNibName:@"WelcomeWindow"];
        [_welcomeWindowController showWindow:self];
    }
    
    GeoserverServer *gs = [GeoserverServer sharedServer];
    GeoserverSettings *settings = [GeoserverSettings sharedSettings];
    [[self.openGeoServerMenuItem menu] setAutoenablesItems: NO];
    [self.openGeoServerMenuItem setEnabled:NO];
    [self.openDashBoardMenuItem setEnabled:NO];
    [self.openGEMenuItem setEnabled:NO];
    [self.openGWCMenuItem setEnabled:NO];
    [self.openRecipesMenuItem setEnabled:NO];
    self.geoserverStatusMenuItem.view = self.geoserverStatusMenuItemViewController.view;
    
    void (^gsStart)() = ^{
        [gs startOnPort:settings.jettyPort terminationHandler:^(NSUInteger status) {
            if (status == 0) {
                if (_welcomeWindowController) {
                    [_welcomeWindowController.setupProgressBar stopAnimation:nil];
                    [_welcomeWindowController.setupStatusText setStringValue:[NSString stringWithFormat:@"Server is now running on port %lu", settings.jettyPort]];
                }
                [self.geoserverStatusMenuItemViewController stopAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Running on Port %u", nil), settings.jettyPort] wasSuccessful:YES];
                [self.openGeoServerMenuItem setEnabled:YES];
                [self.openDashBoardMenuItem setEnabled:YES];
                [self.openGEMenuItem setEnabled:YES];
                [self.openGWCMenuItem setEnabled:YES];
                [self.openRecipesMenuItem setEnabled:YES];
                if (![[NSUserDefaults standardUserDefaults] boolForKey:kGeoserverFirstLaunchPreferenceKey]) {
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [self selectDash:nil];
                }
            } else {
                [self.geoserverStatusMenuItemViewController stopAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Could not start on Port %u", nil), settings.jettyPort] wasSuccessful:NO];
            }
        }];
        
        
        [NSApp activateIgnoringOtherApps:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (!gs.isRunning) {
                [self.geoserverStatusMenuItemViewController startAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Starting Server...", nil), settings.jettyPort]];
                sleep(10);
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (_welcomeWindowController) {
                    [_welcomeWindowController.setupProgressBar stopAnimation:nil];
                    [_welcomeWindowController.setupStatusText setStringValue:[NSString stringWithFormat:@"Server is now running on port %lu", settings.jettyPort]];
                }
                [self.geoserverStatusMenuItemViewController stopAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Running on Port %u", nil), settings.jettyPort] wasSuccessful:YES];
                [self.openGeoServerMenuItem setEnabled:YES];
                [self.openDashBoardMenuItem setEnabled:YES];
                [self.openGEMenuItem setEnabled:YES];
                [self.openGWCMenuItem setEnabled:YES];
                [self.openRecipesMenuItem setEnabled:YES];
                if (![[NSUserDefaults standardUserDefaults] boolForKey:kGeoserverFirstLaunchPreferenceKey]) {
                    [self selectDash:nil];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kGeoserverFirstLaunchPreferenceKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            });
        });
    };
    
    // Install data_dir if needed
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (![fm fileExistsAtPath:gs.dataPath]) {
        if (_welcomeWindowController) {
            [_welcomeWindowController.setupProgressBar startAnimation:nil];
            [_welcomeWindowController.setupStatusText setStringValue:@"Setting up..."];
        }
        [self.geoserverStatusMenuItemViewController startAnimatingWithTitle:@"Setting up Server..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *copyError;
            [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@",gs.binPath] toPath:gs.dataPath error:&copyError];
            [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/data_dir",gs.binPath] toPath:[NSString stringWithFormat:@"%@/../data_dir",gs.dataPath] error:&copyError];
            if (copyError) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSAlert *copyErrorAlert = [NSAlert alertWithMessageText:@"Error setting up GeoServer" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:copyError.localizedDescription];
                    [copyErrorAlert runModal];
                    [self.geoserverStatusMenuItemViewController stopAnimatingWithTitle:NSLocalizedString(@"Could not setup GeoServer", nil) wasSuccessful:NO];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_welcomeWindowController) {
                        [_welcomeWindowController.setupProgressBar startAnimation:nil];
                        [_welcomeWindowController.setupStatusText setStringValue:@"Starting Server..."];
                    }
                    gsStart();
                });
            }
        });
    } else {
        gsStart();
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {    
    [[GeoserverServer sharedServer] stopWithTerminationHandler:^(NSUInteger status) {
        [sender replyToApplicationShouldTerminate:YES];
    }];
    
    // Set a timeout interval for geoserver shutdown
    static NSTimeInterval const kTerminationTimeoutInterval = 3.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kTerminationTimeoutInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [sender replyToApplicationShouldTerminate:YES];
    });
    
    return NSTerminateLater;
}

#pragma mark - IBAction

- (IBAction)selectAbout:(id)sender {
    // Bring application to foreground to have about window display on top of other windows
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (IBAction)selectDocumentation:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kGeoserverAppWebsiteURLString]];
}

- (IBAction)selectGS:(id)sender {
    // Open the GeoServer admin page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%lu/geoserver",[[GeoserverServer sharedServer] port]]]];
}

- (IBAction)selectDash:(id)sender {
    // Open the Dashboard
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%lu/",[[GeoserverServer sharedServer] port]]]];
}

- (IBAction)selectGWC:(id)sender {
    // Open GWC
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%lu/geoserver/gwc",[[GeoserverServer sharedServer] port]]]];
}

- (IBAction)selectGE:(id)sender {
    // Open GeoExplorer
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%lu/geoexplorer",[[GeoserverServer sharedServer] port]]]];
}

- (IBAction)selectRecipes:(id)sender {
    // Open Recipes
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%lu/recipes",[[GeoserverServer sharedServer] port]]]];
}

- (IBAction)selectAutomaticallyStart:(id)sender {
    [self.automaticallyStartMenuItem setState:![self.automaticallyStartMenuItem state]];
    
    NSURL *helperApplicationURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/GeoserverHelper.app"];
    if (LSRegisterURL((__bridge CFURLRef)helperApplicationURL, true) != noErr) {
        NSLog(@"LSRegisterURL Failed");
    }
    
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)@"com.boundlessgeo.GeoserverHelper", [self.automaticallyStartMenuItem state] == NSOnState)) {
        NSLog(@"SMLoginItemSetEnabled Failed");
    }
}

- (IBAction)openWebappsDir:(id)sender {
    NSString *webappsDirLoc = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"jetty"];
    [[NSWorkspace sharedWorkspace] selectFile:[NSString stringWithFormat:@"%@/webapps/geoserver", webappsDirLoc] inFileViewerRootedAtPath:webappsDirLoc];
}

- (IBAction)openDataDir:(id)sender {
    NSString *dataDirLoc = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"data_dir"];
    [[NSWorkspace sharedWorkspace] selectFile:[NSString stringWithFormat:@"%@/global.xml", dataDirLoc] inFileViewerRootedAtPath:dataDirLoc];
}
@end
