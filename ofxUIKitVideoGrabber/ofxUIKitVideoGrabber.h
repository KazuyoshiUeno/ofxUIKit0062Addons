//
//  ofxUIKitVideoGrabber.h
//  viewBasedExample
//
//  Created by 上野 一義 on 11/08/14.
//  Copyright 2011 studio23c.com. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@interface ofxUIKitVideoGrabber : NSObject
<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession*   _session;
    unsigned char* pixels;
    CGImageRef currentFrame;
}
- (unsigned char*)gpixels;
@end
