//
//  AudioRecorderViewController.h
//  LyndaAudio
//
//  Created by John Nastos on 6/23/15.
//  Copyright (c) 2015 Lynda.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AVFoundation;

@interface AudioRecorderViewController : UIViewController <AVAudioRecorderDelegate,AVAudioPlayerDelegate>

@end
