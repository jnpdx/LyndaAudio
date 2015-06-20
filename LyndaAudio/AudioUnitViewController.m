//
//  AudioUnitViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/18/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioUnitViewController.h"

@import AudioToolbox;
@import AVFoundation;

@interface AudioUnitViewController ()

@end

@implementation AudioUnitViewController

static AudioComponentInstance audioUnit;

#define kOutputBus 0
#define kInputBus 1

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    OSStatus err;
    
    //set up the audio unit
    //find the audio (RemoteIO) unit
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    

    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    
    
    err = AudioComponentInstanceNew(comp, &audioUnit);
    if (err != noErr) {
        //error
    }
    
    //set up the audio format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= 44100.00;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 2;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 4;
    audioFormat.mBytesPerFrame		= 4;
    
    err = AudioUnitSetProperty(audioUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               kOutputBus,
                               &audioFormat,
                               sizeof(audioFormat));
    
    if (err != noErr) {
        //error
    }
    
    
    //setup the rendering callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    err = AudioUnitSetProperty(audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        kOutputBus,
                                        &callbackStruct,
                                        sizeof(callbackStruct));
    
    if (err != noErr) {
        //error
    }
    
    
    //register for interrupt notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptListener:) name:AVAudioSessionInterruptionNotification object:nil];
    
}

- (void) interruptListener:(NSNotification*)notification {
    //respond to the notification
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    
    for (int i = 0 ; i < ioData->mNumberBuffers; i++){
        
        
        AudioBuffer buffer = ioData->mBuffers[i];
        UInt32 *frameBuffer = buffer.mData;
        
        //fill the buffer
        for (int k = 0; k < inNumberFrames; k++) {
         
            frameBuffer[k] = arc4random_uniform(UINT32_MAX);
            
        }
    }
    
    
    return noErr;
}

- (IBAction)playButtonPressed:(id)sender {
    AudioOutputUnitStart(audioUnit);
}

- (IBAction)stopButtonPressed:(id)sender {
    AudioOutputUnitStop(audioUnit);
}

- (void) dealloc {
    //TOOD: dispose of the audio unit / resources
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
