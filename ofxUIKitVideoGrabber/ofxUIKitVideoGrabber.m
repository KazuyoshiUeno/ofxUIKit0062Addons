//
//  ofxUIKitVideoGrabber.m
//  viewBasedExample
//
//  Created by 上野 一義 on 11/08/14.
//  Copyright 2011 studio23c.com. All rights reserved.
//

#import "ofxUIKitVideoGrabber.h"


@implementation ofxUIKitVideoGrabber

#pragma mark -
#pragma mark Initialize
- (unsigned char*)gpixels
{
    return pixels;
}

- (void)_init
{
    
    //  pixcel allocate
    pixels = malloc(480*360*4);
 
    
    // ビデオキャプチャデバイスの取得
    AVCaptureDevice*    device;
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // デバイス入力の取得
    AVCaptureDeviceInput*   deviceInput;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    
    // ビデオデータ出力の作成
    NSMutableDictionary*        settings;
    AVCaptureVideoDataOutput*   dataOutput;
    settings = [NSMutableDictionary dictionary];
    [settings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dataOutput.alwaysDiscardsLateVideoFrames = YES;
    dataOutput.minFrameDuration = CMTimeMake(1, 15);
    [dataOutput autorelease];
    dataOutput.videoSettings = settings;
    
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // セッションの作成
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPresetMedium]; 
    [_session addInput:deviceInput];
    [_session addOutput:dataOutput];
    [_session commitConfiguration];
    
    // セッションの開始
    [_session startRunning];

    
	[deviceInput.device lockForConfiguration:nil];
	
    
	if( [deviceInput.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] )	
        [deviceInput.device setFocusMode:AVCaptureFocusModeAutoFocus ];
    
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self _init];
    }
    return self;
}


#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput*)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection*)connection
{
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    // イメージバッファの取得
    CVImageBufferRef    buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // イメージバッファ情報の取得
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    
    // ビットマップコンテキストの作成
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(
                                      base, width, height, 8, bytesPerRow, colorSpace, 
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    
    //----------------- grabber -----------------------
    // 画像データの作成
    CGImageRef  cgImage;
    cgImage = CGBitmapContextCreateImage(cgContext);
    CGContextRelease(cgContext);
    
    CGImageRelease(currentFrame);	
	currentFrame = CGImageCreateCopy(cgImage);
    CGImageRelease(cgImage);
    
    
    //------------------------------------------------
    //  トライ２
	CGContextRef spriteContext;
    
	int bytesPerPixel	= CGImageGetBitsPerPixel(currentFrame)/8;
	if(bytesPerPixel == 3) bytesPerPixel = 4;
	
	int w			= CGImageGetWidth(currentFrame);
	int h			= CGImageGetHeight(currentFrame);
	
	// Allocated memory needed for the bitmap context [GLubyte]
	unsigned char *pixelsTmp	= (unsigned char *) malloc(w * h * bytesPerPixel);
	
     // Uses the bitmatp creation function provided by the Core Graphics framework. 
     spriteContext = CGBitmapContextCreate(pixelsTmp, 
                                           w, 
                                           h, 
                                           CGImageGetBitsPerComponent(currentFrame), 
                                           w * bytesPerPixel, 
                                           CGImageGetColorSpace(currentFrame), 
                                           bytesPerPixel == 4 ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone);
     
     if (spriteContext == NULL) 
     {
         NSLog(@"convertCGImageToPixels - CGBitmapContextCreate returned NULL");
         free(pixelsTmp);
     }
     
     CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, (CGFloat)w, (CGFloat)h), currentFrame);
     CGContextRelease(spriteContext);
     
	int totalSrcBytes = w*h*bytesPerPixel;  
	int j = 0;
	for(int k = 0; k < totalSrcBytes; k+= bytesPerPixel )
    {
		pixels[j] = pixelsTmp[k];
		pixels[j+1] = pixelsTmp[k+1];
		pixels[j+2] = pixelsTmp[k+2];
		
		j+=3;
	}
    
	free(pixelsTmp);

    // イメージバッファのアンロック
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    [pool drain];
}
@end
