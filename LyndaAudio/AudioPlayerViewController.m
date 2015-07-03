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
    
    [self setupAudio];
}

- (void) setupAudio {
    //TODO: register app for background playing?
    
    NSError *error;
    
    //set up the audio session
    [[AVAudioSession sharedInstance] setActive:YES withOptions:0 error:&error];
    if (error != nil) {
        NSAssert(error == nil, @"Error setting audio session to active: %@",error);
    }
    
    //set the category
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error != nil) {
        NSAssert(error == nil, @"Error setting audio category: %@",error);
    }
    
    //load up the audio
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"SoManyTimes" withExtension:@"mp3"];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    if (error != nil) {
        NSAssert(error == nil, @"Error loading audioPlayer: %@",error);
    } else {
        [self.audioPlayer setVolume:self.rateSlider.value];
        [self.audioPlayer prepareToPlay];
    }
    
    //register for interruption
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void) audioInterrupt:(NSNotification*)notification {
    //handle an interruption
    NSDictionary *interruptionDictionary = [notification userInfo];
    NSNumber *interruptionType = (NSNumber *)[interruptionDictionary valueForKey:AVAudioSessionInterruptionTypeKey];
    switch ([interruptionType intValue]) {
        case AVAudioSessionInterruptionTypeBegan:
            [self stopButtonPressed:nil];
            break;
        case AVAudioSessionInterruptionTypeEnded:
            [self playButtonPressed:self];
            break;
        default:
            break;
    }
    
}

- (void) audioRouteChange:(NSNotification*)notification {
    //handle a route change
}

- (IBAction)rateSliderChanged:(UISlider*)sender {
    [self.audioPlayer setVolume:self.rateSlider.value];
}

- (IBAction)playButtonPressed:(id)sender {
    BOOL played = [self.audioPlayer play];
    NSAssert(played == YES, @"Failed playing");
}

- (IBAction)stopButtonPressed:(id)sender {
    [self.audioPlayer stop];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
