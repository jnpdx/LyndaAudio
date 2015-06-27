//
//  AudioUnitInputViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/27/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioUnitInputViewController.h"

@import AVFoundation;

@interface AudioUnitInputViewController ()

@property (weak,nonatomic) IBOutlet UIView *colorView;

@end

static AudioComponentInstance audioUnit;

#define kOutputBus 0
#define kInputBus 1

@implementation AudioUnitInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAudio];
}

- (void) setupAudio {
    OSStatus err;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    err = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if (err != noErr) {
        //error
    }
    
    // Enable IO for recording
    UInt32 flag = 1;
    err = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }
    
    // Enable IO for playback
    err = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = 44100.00;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 2;
    audioFormat.mBytesPerFrame      = 2;
    
    
    // Apply format
    err = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }
    
    err = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    err = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }
    
//    // Set output callback
//    callbackStruct.inputProc = playbackCallback;
//    callbackStruct.inputProcRefCon = (__bridge void *)(self);
//    err = AudioUnitSetProperty(audioUnit,
//                                  kAudioUnitProperty_SetRenderCallback,
//                                  kAudioUnitScope_Global,
//                                  kOutputBus,
//                                  &callbackStruct,
//                                  sizeof(callbackStruct));
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }

    // Initialise
    err = AudioUnitInitialize(audioUnit);
    if (err != noErr) {
        NSLog(@"Error: %i",err);
    }
}

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // TODO: Use inRefCon to access our interface object to do stuff
    // Then, use inNumberFrames to figure out how much data is available, and make
    // that much space available in buffers in an AudioBufferList.
    
    AudioBuffer buffer;
    
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * 2;
    buffer.mData = malloc( inNumberFrames * 2 );
    
    // Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // Then:
    // Obtain recorded samples
    
    OSStatus status;
    
    status = AudioUnitRender(audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    if (status != noErr) {
        //error
    }
    
    SInt16 *frameBuffer = buffer.mData;
    
    UInt32 totalAmplitude = 0;
    
    for (int i = 0; i < inNumberFrames; i++) {
        //loop through the buffer
        //printf("%i",frameBuffer[i]);
        totalAmplitude += abs(frameBuffer[i]);
    }
    totalAmplitude /= inNumberFrames;
    
    float alphaFloat = (float)totalAmplitude / (float)SHRT_MAX * 2;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ((__bridge AudioUnitInputViewController*)inRefCon).colorView.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:alphaFloat];
    });
    
    // Now, we have the samples we just read sitting in buffers in bufferList
    //DoStuffWithTheRecordedAudio(bufferList);
    return noErr;
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    //printf("Here");
    return noErr;
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
    
    OSStatus err = AudioOutputUnitStart(audioUnit);
    if (err != noErr) {
        //error
    }
}

- (IBAction)stopButtonPressed:(id)sender {
    OSStatus err = AudioOutputUnitStop(audioUnit);
    if (err != noErr) {
        //error
    }
    self.colorView.backgroundColor = [UIColor clearColor];
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
