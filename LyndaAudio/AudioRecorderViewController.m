//
//  AudioRecorderViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/23/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioRecorderViewController.h"

@import AVFoundation;

@interface AudioRecorderViewController ()

@property (nonatomic,strong) NSURL *audioFile;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

@property (nonatomic,weak) IBOutlet UILabel *statusLabel;
@property (nonatomic,weak) IBOutlet UIButton *recordButton;
@property (nonatomic,weak) IBOutlet UIButton *playButton;

@end

@implementation AudioRecorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSString *directoryName = NSTemporaryDirectory();
    NSString *generatedFileName =
    [directoryName stringByAppendingPathComponent:@"audioFile.wav"];
    
    self.audioFile = [NSURL URLWithString:generatedFileName];
    
    NSDictionary *recordSettings = @{
                                     AVFormatIDKey: @(kAudioFormatLinearPCM),
                                     AVSampleRateKey: @(44100.0),
                                     AVNumberOfChannelsKey: @2,
                                     AVLinearPCMBitDepthKey: @16,
                                     AVLinearPCMIsBigEndianKey: @NO,
                                     AVLinearPCMIsFloatKey: @NO,
                                     };
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.audioFile settings:recordSettings error:&error];
    if (error != nil) {
        //error
    }
    self.audioRecorder.delegate = self;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    self.statusLabel.text = @"";
    [self enableButtons];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.statusLabel.text = @"";
    [self enableButtons];
}

- (void) enableButtons {
    [self.recordButton setEnabled:YES];
    [self.playButton setEnabled:YES];
}

- (void) disableButtons {
    [self.recordButton setEnabled:NO];
    [self.playButton setEnabled:NO];
}

- (IBAction)recordButtonPressed:(id)sender {
    NSError *error;
    
    //set up the audio session
    [[AVAudioSession sharedInstance] setActive:YES withOptions:0 error:&error];
    if (error != nil) {
        //error
    }
    
    //set the category
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error != nil) {
        //error
    }
    
    [self.audioRecorder prepareToRecord];
    
    BOOL recorded = [self.audioRecorder recordForDuration:10.0];
    if (!recorded) {
        NSLog(@"Error");
    }
    self.statusLabel.text = @"Recording for 10 sec...";
    [self disableButtons];
}

- (IBAction)playButtonPressed:(id)sender {
    if (self.audioRecorder.isRecording) {
        //it's still recording
        return;
    }
    
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.audioFile error:&error];
    if (error != nil) {
        //error
    }
    
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
    
    self.audioPlayer.delegate = self;
    [self.audioPlayer play];
    self.statusLabel.text = @"Playing...";
    [self disableButtons];
}


@end
