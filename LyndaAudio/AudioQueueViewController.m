//
//  AudioQueueViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/29/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioQueueViewController.h"

@import AVFoundation;


typedef NS_ENUM(NSUInteger, AudioQueueState) {
    AudioQueueState_Idle,
    AudioQueueState_Recording,
    AudioQueueState_Playing,
};

@interface AudioQueueViewController () {
}

@property (nonatomic,strong) NSURL *audioFile;
@property AudioQueueState currentQueueState;

@end

@implementation AudioQueueViewController

#define NUM_BUFFERS 10

static AudioStreamBasicDescription audioFormat;

static SInt64 currentPacket;
static AudioQueueRef queue;
static AudioQueueBufferRef buffers[NUM_BUFFERS];
static AudioFileID audioFileID;

void AudioInputCallback(void * inUserData, 
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs) {
    
    AudioQueueViewController* viewController = ((__bridge AudioQueueViewController*)inUserData);
    
    if (viewController.currentQueueState != AudioQueueState_Recording)
        return;
    
    OSStatus err;
    
    printf("Writing buffer %lld\n", currentPacket);

    err = AudioFileWritePackets(audioFileID,
                            false,
                            inBuffer->mAudioDataByteSize,
                            inPacketDescs,
                            currentPacket,
                            &inNumberPacketDescriptions,
                            inBuffer->mAudioData);
    
    if (err != noErr) {
        //error
        printf("Recording error! %i\n",err);
    }
    
    currentPacket += inNumberPacketDescriptions;
    
    AudioQueueEnqueueBuffer(queue, inBuffer, 0, NULL);
}

void AudioOutputCallback(void * inUserData,
                         AudioQueueRef outAQ,
                         AudioQueueBufferRef outBuffer) {
    
    
    AudioQueueViewController* viewController = ((__bridge AudioQueueViewController*)inUserData);
    
    if (viewController.currentQueueState != AudioQueueState_Playing) {
        printf("Not playing -- return\n");
        return;
    }
    
    printf("Queuing buffer %lld for playback\n", currentPacket);
    
    AudioStreamPacketDescription* packetDescs;
    
    UInt32 bytesRead;
    UInt32 numPackets = 8000;
    OSStatus err;
    
    err = AudioFileReadPacketData(audioFileID, false, &bytesRead, NULL, currentPacket, &numPackets, outBuffer->mAudioData);
    
    if (err != noErr) {
        printf("Error %i\n\n",err);
        [viewController handleError];
    }
    
    if (numPackets)
    {
        printf("Read %i bytes\n",bytesRead);
        outBuffer->mAudioDataByteSize = bytesRead;
        err = AudioQueueEnqueueBuffer(queue,
                                         outBuffer,
                                         0,
                                         packetDescs);
        
        currentPacket += numPackets;
    }
    else
    {
        if (viewController.currentQueueState == AudioQueueState_Playing)
        {
            printf("Stopping while playing\n");
            AudioQueueStop(queue, false);
            AudioFileClose(audioFileID);
            viewController.currentQueueState = AudioQueueState_Idle;
        }
        
        AudioQueueFreeBuffer(queue, outBuffer);
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentQueueState = AudioQueueState_Idle;
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
    switch (self.currentQueueState) {
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
    
    NSError *error;
    //set up the audio session
    [[AVAudioSession sharedInstance] setActive:YES withOptions:0 error:&error];
    if (error != nil) {
        NSAssert(error == nil,@"Error setting audio session to active");
    }
    
    //set the category
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
    if (error != nil) {
        NSAssert(error == nil,@"Error setting audio session category");
    }
    
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            
            
            
            self.currentQueueState = AudioQueueState_Recording;
            currentPacket = 0;
            
            OSStatus err;
            
            err = AudioQueueNewInput(&audioFormat, AudioInputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &queue);
            NSAssert(err == noErr,@"Error setting up audio queue: %i",err);
            
            //allocate the buffers
            for (int i = 0; i < NUM_BUFFERS; i++) {
                AudioQueueAllocateBuffer(queue, 16000, &buffers[i]);
                AudioQueueEnqueueBuffer (queue, buffers[i], 0, NULL);
            }
            
            NSString *directoryName = NSTemporaryDirectory();
            
            NSString *generatedFileName =
            [directoryName stringByAppendingPathComponent:@"audioQueueFile.aif"];
            
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
            
        } else {
            NSAssert(NO, @"No mic permission");
        }
    }];
    
    
}

- (void) stopRecording {
    self.currentQueueState = AudioQueueState_Idle;
    
    AudioQueueStop(queue, true);
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(queue, buffers[i]);
    }
    
    AudioQueueDispose(queue, true);
    AudioFileClose(audioFileID);
    
    NSLog(@"Stopped recording");
}


- (IBAction)playButtonPressed:(id)sender {
    switch (self.currentQueueState) {
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
    
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:YES withOptions:0 error:&error];
    if (error != nil) {
        NSAssert(error == nil,@"Error setting audio session to active");
    }
    
    //set the category
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error != nil) {
        NSAssert(error == nil,@"Error setting audio session category");
    }
    
    [self startPlayback];
}

- (void) startPlayback {
    NSLog(@"Starting playback method");
    
    //[self stopPlayback];
    
    currentPacket = 0;
    
    OSStatus err;
    
    err = AudioFileOpenURL((__bridge CFURLRef)(self.audioFile), kAudioFileReadPermission, kAudioFileAIFFType, &audioFileID);
    
    NSAssert(err == noErr,@"");
    
    err = AudioQueueNewOutput(&audioFormat,
                        AudioOutputCallback,
                        (__bridge void *)(self),
                        CFRunLoopGetCurrent(),
                        kCFRunLoopCommonModes,
                        0,
                        &queue);
    
    NSLog(@"Made output queue");
    
    NSAssert(err == noErr,@"");
    
    self.currentQueueState = AudioQueueState_Playing;
    
    for (int i = 0; i < NUM_BUFFERS && self.currentQueueState == AudioQueueState_Playing; i++)
    {
        AudioQueueAllocateBuffer(queue, 16000, &buffers[i]);
        printf("Calling callback from loop\n");
        AudioOutputCallback((__bridge void *)(self), queue, buffers[i]);
    }
    
    printf("Calling start on output\n");
    err = AudioQueueStart(queue, NULL);
    
    NSAssert(err == noErr,@"");
    
}

- (void) handleError {
    NSAssert(false, @"");
}

- (void) stopPlayback {
    NSLog(@"Stop playback called");
    self.currentQueueState = AudioQueueState_Idle;
    
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(queue, buffers[i]);
    }
    
    AudioQueueDispose(queue, true);
    AudioFileClose(audioFileID);
}

- (void)dealloc {
    [self stopPlayback];
}

@end
