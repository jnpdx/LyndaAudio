//
//  FirstViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/18/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "SystemSoundServicesViewController.h"

@import AudioToolbox;

@interface SystemSoundServicesViewController ()

@property SystemSoundID theSoundID;

@end

@implementation SystemSoundServicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAudio];
}

- (void) setupAudio {
    NSURL *soundPathURL = [[NSBundle mainBundle] URLForResource:@"MetalBell" withExtension:@"wav"];
    OSStatus err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundPathURL, &_theSoundID);
    if (err != noErr) {
        NSAssert(err == noErr, @"Couldn't create system sound ID");
    }
}

- (IBAction)soundButtonPressed:(id)sender {
    AudioServicesPlaySystemSound(self.theSoundID);
}

- (void)dealloc {
    AudioServicesDisposeSystemSoundID(self.theSoundID);
}

@end
