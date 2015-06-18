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

@property SystemSoundID soundObject;

@end

@implementation SystemSoundServicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)soundButtonPressed:(id)sender {
    NSString *soundPath = [[NSBundle mainBundle]
                            pathForResource:@"Cowbell" ofType:@"wav"];
    NSURL *soundPathURL = [NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundPathURL, &_soundObject);
    AudioServicesPlaySystemSound(self.soundObject);
}

@end
