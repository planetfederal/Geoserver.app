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
@synthesize automaticallyOpenDocumentationMenuItem = _automaticallyOpenDocumentationMenuItem;
@synthesize automaticallyStartMenuItem = _automaticallyStartMenuItem;

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    _statusBarItem.highlightMode = YES;
    _statusBarItem.menu = self.statusBarMenu;
    _statusBarItem.image = [NSImage imageNamed:@"status-off"];
    _statusBarItem.alternateImage = [NSImage imageNamed:@"status-on"];
        
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kGeoserverAutomaticallyOpenDocumentationPreferenceKey]];
    [self.automaticallyOpenDocumentationMenuItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:kGeoserverAutomaticallyOpenDocumentationPreferenceKey]];
    [self.automaticallyStartMenuItem setState:GeoserverIsHelperApplicationSetAsLoginItem() ? NSOnState : NSOffState];
    
    [[GeoserverServer sharedServer] startOnPort:kGeoserverAppDefaultPort terminationHandler:^(NSUInteger status) {
        if (status == 0) {
            [self.geoserverStatusMenuItemViewController stopAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Running on Port %u", nil), kGeoserverAppDefaultPort] wasSuccessful:YES];
        } else {
            [self.geoserverStatusMenuItemViewController stopAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Could not start on Port %u", nil), kGeoserverAppDefaultPort] wasSuccessful:NO];
        }
    }];
    
    [NSApp activateIgnoringOtherApps:YES];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kGeoserverFirstLaunchPreferenceKey]) {
        _welcomeWindowController = [[WelcomeWindowController alloc] initWithWindowNibName:@"WelcomeWindow"];
        [_welcomeWindowController showWindow:self];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kGeoserverFirstLaunchPreferenceKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:kGeoserverAutomaticallyOpenDocumentationPreferenceKey]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kGeoserverAppWebsiteURLString]];
    }
    
    [self.geoserverStatusMenuItem setEnabled:NO];
    self.geoserverStatusMenuItem.view = self.geoserverStatusMenuItemViewController.view;
    [self.geoserverStatusMenuItemViewController startAnimatingWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Running on Port %u", nil), kGeoserverAppDefaultPort]];
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8080/geoserver"]];
}

- (IBAction)selectAutomaticallyOpenDocumentation:(id)sender {
    [self.automaticallyOpenDocumentationMenuItem setState:![self.automaticallyOpenDocumentationMenuItem state]];

    [[NSUserDefaults standardUserDefaults] setBool:self.automaticallyOpenDocumentationMenuItem.state == NSOnState forKey:kGeoserverAutomaticallyOpenDocumentationPreferenceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

@end
