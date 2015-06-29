//
//  AudioQueueViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/29/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioQueueViewController.h"

@import AudioToolbox;

typedef NS_ENUM(NSUInteger, AudioQueueState) {
    AudioQueueState_Idle,
    AudioQueueState_Recording,
    AudioQueueState_Playing,
};

@interface AudioQueueViewController () {
    AudioQueueState currentState;
}

@property (nonatomic,strong) NSURL *audioFile;

@end

@implementation AudioQueueViewController

#define NUM_BUFFERS 10

static AudioStreamBasicDescription audioFormat;

static SInt64 currentPacket;
static AudioQueueRef queue;
static AudioQueueBufferRef buffers[NUM_BUFFERS];
static AudioFileID audioFileID;

void AudioInputCallback(void * inUserData,  // Custom audio metadata
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs) {
    
}

void AudioOutputCallback(void * inUserData,
                         AudioQueueRef outAQ,
                         AudioQueueBufferRef outBuffer) {
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    currentState = AudioQueueState_Idle;
    [self setupAudio];
}

- (void) setupAudio {
    // Describe format
    
    audioFormat.mSampleRate         = 44100.00;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerFrame		= audioFormat.mChannelsPerFrame * sizeof(SInt16);
    audioFormat.mBytesPerPacket		= audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    
}

- (IBAction) recordButtonPressed:(id)sender {
    switch (currentState) {
        case AudioQueueState_Idle:
            break;
        case AudioQueueState_Playing:
            return;
        case AudioQueueState_Recording:
            [self stopRecording];
            return;
        default:
            break;
    }
    
#warning set the audio session up
    
    currentState = AudioQueueState_Recording;
    
    OSStatus err;
    
    err = AudioQueueNewInput(&audioFormat, AudioInputCallback, NULL, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &queue);
    NSAssert(err == noErr,@"Error setting up audio queue: %i",err);
    
    //allocate the buffers
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(queue, 16000, &buffers[i]);
        AudioQueueEnqueueBuffer (queue, buffers[i], 0, NULL);
    }
    
    NSString *directoryName = NSTemporaryDirectory();
    NSString *generatedFileName =
    [directoryName stringByAppendingPathComponent:@"audioQueueFile.wav"];
    
    self.audioFile = [NSURL URLWithString:generatedFileName];
    
    
    err = AudioFileCreateWithURL((__bridge CFURLRef)(self.audioFile),
                                 kAudioFileAIFFType,
                                 &audioFormat,
                                 kAudioFileFlags_EraseFile,
                                 &audioFileID);
    NSAssert(err == noErr,@"Error setting up audio queue recording file: %i",err);
    
    err = AudioQueueStart(queue, NULL);
    NSAssert(err == noErr,@"Error starting audio queue %i",err);
    
    NSLog(@"Recording");
}

- (void) stopRecording {
    AudioQueueStop(queue, true);
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(queue, buffers[i]);
    }
    
    AudioQueueDispose(queue, true);
    AudioFileClose(audioFileID);
    
    currentState = AudioQueueState_Idle;
    
    NSLog(@"Stopped recording");
}

- (void) stopPlayback {
    
    for(int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(queue, buffers[i]);
    }
    
    AudioQueueDispose(queue, true);
    AudioFileClose(audioFileID);
    
    currentState = AudioQueueState_Idle;
    
    NSLog(@"Stopped playback");
}

- (IBAction)playButtonPressed:(id)sender {
    switch (currentState) {
        case AudioQueueState_Idle:
            break;
        case AudioQueueState_Playing:
            [self stopPlayback];
            return;
        case AudioQueueState_Recording:
            [self stopRecording];
            break;
        default:
            break;
    }
    
    currentState = AudioQueueState_Playing;
    
    currentPacket = 0;
    
    OSStatus err;
    
    err = AudioQueueNewOutput(&audioFormat,
                              AudioOutputCallback,
                              NULL,
                              CFRunLoopGetCurrent(),
                              kCFRunLoopCommonModes,
                              0,
                              &queue);
    
    NSAssert(err == noErr,@"Error creating output queue %i",err);
    
    for (int i = 0; i < NUM_BUFFERS && (currentState == AudioQueueState_Playing); i++) {
        AudioQueueAllocateBuffer(queue, 16000, &buffers[i]);
        AudioOutputCallback(NULL, queue, buffers[i]);
    }
    
    err = AudioQueueStart(queue, NULL);
    
    NSAssert(err == noErr,@"Error creating starting queue %i",err);
    
    NSLog(@"Playing");
}

@end
