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
    
    [self setupAudio];
}

- (void) setupAudio {
#warning Set up the audio session
    
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

static double theta = 0;
static float frequency = 440.0;

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    const double amplitude = 0.5;
    const int sampleRate = 44100;
    const double increment = 2.0 * M_PI * frequency / sampleRate;
    
    for (int i = 0 ; i < ioData->mNumberBuffers; i++){
        
        
        AudioBuffer buffer = ioData->mBuffers[i];
        UInt32 *frameBuffer = buffer.mData;
        
        //fill the buffer
        for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
         
            double sinValueInRadians = sin(theta);
            
            SInt16 val = sinValueInRadians / (2.0 * M_PI) * SHRT_MAX * amplitude;
            
            SInt16 newFrameInMemory[2] = {val, val};
            
            UInt32 newFrame32 = *((UInt32*)&newFrameInMemory);
                        
            //frameBuffer[frame] = arc4random_uniform(UINT32_MAX);

            frameBuffer[frame] = newFrame32;
            
            
            theta += increment;
            if (theta > 2.0 * M_PI)
            {
                theta -= 2.0 * M_PI;
            }
        }
    }
    
    return noErr;
}

- (IBAction)sliderMoved:(UISlider*)sender {
    frequency = sender.value;
}

- (IBAction)playButtonPressed:(id)sender {
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
    
    AudioOutputUnitStart(audioUnit);
}

- (IBAction)stopButtonPressed:(id)sender {
    AudioOutputUnitStop(audioUnit);
    
    NSError *error;
    //set up the audio session
    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:&error];
    if (error != nil) {
        //error
    }
}

- (void) dealloc {
    OSStatus err = AudioComponentInstanceDispose(audioUnit);
    if (err != noErr) {
        //error
    }
}

@end
