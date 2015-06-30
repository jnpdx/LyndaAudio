//
//  AudioQueueViewController.m
//  LyndaAudio
//
//  Created by John Nastos on 6/29/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import "AudioQueueViewController.h"

@import AudioToolbox;

static const int kNumberBuffers = 3;                              // 1
typedef struct {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
    AudioFileID                   mAudioFile;                     // 5
    UInt32                        bufferByteSize;                 // 6
    SInt64                        mCurrentPacket;                 // 7
    UInt32                        mNumPacketsToRead;              // 8
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
    bool                          mIsRunning;                     // 10
} AQPlayerState;

static void HandleOutputBuffer (
                                void                *aqData,
                                AudioQueueRef       inAQ,
                                AudioQueueBufferRef inBuffer
                                ) {
    AQPlayerState *pAqData = (AQPlayerState *) aqData;        // 1
    if (pAqData->mIsRunning == 0) return;                     // 2
    UInt32 numBytesReadFromFile;                              // 3
    UInt32 numPackets = pAqData->mNumPacketsToRead;           // 4
    AudioFileReadPackets (
                          pAqData->mAudioFile,
                          false,
                          &numBytesReadFromFile,
                          pAqData->mPacketDescs,
                          pAqData->mCurrentPacket,
                          &numPackets,
                          inBuffer->mAudioData
                          );
    if (numPackets > 0) {                                     // 5
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;  // 6
        AudioQueueEnqueueBuffer (
                                 pAqData->mQueue,
                                 inBuffer,
                                 (pAqData->mPacketDescs ? numPackets : 0),
                                 pAqData->mPacketDescs
                                 );
        pAqData->mCurrentPacket += numPackets;                // 7 
    } else {
        AudioQueueStop (
                        pAqData->mQueue,
                        false
                        );
        pAqData->mIsRunning = false; 
    }
}

void DeriveBufferSize (
                       AudioStreamBasicDescription ASBDesc,                            // 1
                       UInt32                      maxPacketSize,                       // 2
                       Float64                     seconds,                             // 3
                       UInt32                      *outBufferSize,                      // 4
                       UInt32                      *outNumPacketsToRead                 // 5
) {
    static const int maxBufferSize = 0x50000;                        // 6
    static const int minBufferSize = 0x4000;                         // 7
    
    if (ASBDesc.mFramesPerPacket != 0) {                             // 8
        Float64 numPacketsForTime =
        ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {                                                         // 9
        *outBufferSize =
        maxBufferSize > maxPacketSize ?
        maxBufferSize : maxPacketSize;
    }
    
    if (                                                             // 10
        *outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize
        )
        *outBufferSize = maxBufferSize;
    else {                                                           // 11
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;           // 12
}

typedef NS_ENUM(NSUInteger, AudioQueueState) {
    AudioQueueState_Idle,
    AudioQueueState_Recording,
    AudioQueueState_Playing,
};

@interface AudioQueueViewController () {
}

@property (nonatomic,strong) NSURL *audioFile;
@property AudioQueueState currentState;

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
    
    AudioQueueViewController* viewController = ((__bridge AudioQueueViewController*)inUserData);
    
    if (viewController.currentState != AudioQueueState_Recording)
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
    
    if (viewController.currentState != AudioQueueState_Playing)
        return;
    
    printf("Queueing buffer %i\n",currentPacket);
    
    AudioStreamPacketDescription* packetDescs;
    
    UInt32 bytesRead;
    UInt32 numPackets = 8000;
    OSStatus err;
    err = AudioFileReadPackets(audioFileID,
                                  false,
                                  &bytesRead,
                                  packetDescs,
                                  currentPacket,
                                  &numPackets,
                                  outBuffer->mAudioData);

    
    if (err != noErr) {
        //error
        printf("Playback error! %i\n",err);
    }
    
    if (numPackets)
    {
        outBuffer->mAudioDataByteSize = bytesRead;
        err = AudioQueueEnqueueBuffer(queue,
                                         outBuffer,
                                         0,
                                         packetDescs);
        
        if (err != noErr) {
            printf("Error enqueing buffer: %i\n\n",err);
        }
        currentPacket += numPackets;
    }
    else
    {
        printf("Stopping while playing...\n\n");
        //return;
        //stop playback
        [viewController stopPlayback];
        
        //AudioQueueFreeBuffer(queue, outBuffer);
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentState = AudioQueueState_Idle;
    [self setupAudio];
}

- (void) setupAudio {
    // Describe format
    
    audioFormat.mSampleRate         = 8000.00;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerFrame		= audioFormat.mChannelsPerFrame * sizeof(SInt16);
    audioFormat.mBytesPerPacket		= audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    
}

- (IBAction) recordButtonPressed:(id)sender {
    switch (self.currentState) {
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
    
    self.currentState = AudioQueueState_Recording;
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
}

- (void) stopRecording {
    self.currentState = AudioQueueState_Idle;
    
    AudioQueueStop(queue, true);
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(queue, buffers[i]);
    }
    
    AudioQueueDispose(queue, true);
    AudioFileClose(audioFileID);
    
    
    NSLog(@"Stopped recording");
}

- (void) stopPlayback {
    NSLog(@"Got stop call");
    
    if (self.currentState != AudioQueueState_Playing) return;
    
    AudioQueueStop(queue,false);
    
    for(int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(queue, buffers[i]);
    }
    
    AudioQueueDispose(queue, true);
    AudioFileClose(audioFileID);
    
    self.currentState = AudioQueueState_Idle;
    
    NSLog(@"Stopped playback");
}

- (IBAction)playButtonPressed:(id)sender {
    switch (self.currentState) {
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
    
    
    currentPacket = 0;
    
    OSStatus err;
    
    err = AudioFileOpenURL((__bridge CFURLRef)(self.audioFile), kAudioFileReadPermission, kAudioFileAIFFType, &audioFileID);

    NSAssert(err == noErr,@"Error opening file %i",err);
    
    err = AudioQueueNewOutput(&audioFormat,
                              AudioOutputCallback,
                              (__bridge void *)(self),
                              CFRunLoopGetCurrent(),
                              kCFRunLoopCommonModes,
                              0,
                              &queue);
    
    NSAssert(err == noErr,@"Error creating output queue %i",err);
    
    self.currentState = AudioQueueState_Playing;
    
    for (int i = 0; i < NUM_BUFFERS && (self.currentState == AudioQueueState_Playing); i++) {
        AudioQueueAllocateBuffer(queue, 16000, &buffers[i]);
        AudioOutputCallback((__bridge void *)(self), queue, buffers[i]);
    }
    
    printf("Calling start on output\n");
    err = AudioQueueStart(queue, NULL);
    
    NSAssert(err == noErr,@"Error starting output queue %i",err);
    
    NSLog(@"Playing");
}

@end
