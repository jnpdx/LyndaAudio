//
//  SecondViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/18/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioPlayerViewController.h"

@import AVFoundation;

@interface AudioPlayerViewController ()

@property (weak, nonatomic) IBOutlet UISlider *rateSlider;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation AudioPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *error;
    
    //set up the audio session
    [[AVAudioSession sharedInstance] setActive:YES withOptions:0 error:&error];
    if (error != nil) {
        //error
    }
    
    //set the category
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error != nil) {
        //error
    }
    
    //load up the audio
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"SoManyTimes" withExtension:@"mp3"];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    if (error != nil) {
        //error
    } else {
        [self.audioPlayer setVolume:self.rateSlider.value];
        [self.audioPlayer prepareToPlay];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)rateSliderChanged:(UISlider*)sender {
    [self.audioPlayer setVolume:self.rateSlider.value];
}

- (IBAction)playButtonPressed:(id)sender {
    [self.audioPlayer play];
}

- (IBAction)stopButtonPressed:(id)sender {
    [self.audioPlayer stop];
}

@end
