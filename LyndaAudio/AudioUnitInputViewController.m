//
//  AudioUnitInputViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/27/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioUnitInputViewController.h"

@import AudioToolbox;
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
        NSAssert(NO, @"Couldn't get audio component");
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
    audioFormat.mBytesPerFrame		= audioFormat.mChannelsPerFrame * sizeof(SInt16);
    audioFormat.mBytesPerPacket		= audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    
    
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
    
    
    AudioBuffer buffer;
    
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * sizeof(SInt16);
    buffer.mData = malloc( buffer.mDataByteSize );
    
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
    
    double totalAmplitude = 0;
    
    for (int i = 0; i < inNumberFrames; i++) {
        //loop through the buffer
        //printf("%i",frameBuffer[i]);
        totalAmplitude += frameBuffer[i] * frameBuffer[i];
    }
    totalAmplitude /= inNumberFrames;
    
    totalAmplitude = sqrt(totalAmplitude);
    
    float alphaFloat = totalAmplitude / (float)SHRT_MAX * 2;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ((__bridge AudioUnitInputViewController*)inRefCon).colorView.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:alphaFloat];
    });
    
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
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            OSStatus err = AudioOutputUnitStart(audioUnit);
            if (err != noErr) {
                //error
            }
        } else {
            NSAssert(NO, @"No mic permission");
        }
    }];
    
    
}

- (IBAction)stopButtonPressed:(id)sender {
    OSStatus err = AudioOutputUnitStop(audioUnit);
    if (err != noErr) {
        //error
    }
    self.colorView.backgroundColor = [UIColor clearColor];
    
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:&error];
}


@end
