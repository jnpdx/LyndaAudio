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
    
    [self.audioPlayer play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
