//
//  FirstViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/18/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "SystemSoundServicesViewController.h"

#import <AudioToolbox/AudioToolbox.h>

@interface SystemSoundServicesViewController ()

@property SystemSoundID theSoundID;

@end

@implementation SystemSoundServicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *soundPathURL = [[NSBundle mainBundle] URLForResource:@"Cowbell" withExtension:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundPathURL, &_theSoundID);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)soundButtonPressed:(id)sender {
    AudioServicesPlaySystemSound(self.theSoundID);
}

- (void)dealloc {
    AudioServicesDisposeSystemSoundID(self.theSoundID);
}

@end
