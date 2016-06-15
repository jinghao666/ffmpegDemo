//
//  H264Decoder.h
//  FFMpegDemo
//
//  Created by tongguan on 16/6/15.
//  Copyright © 2016年 MinorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum _H264DecoderStatus{
    H264DecoderPlaying,
    H264DecoderStopped
}H264DecoderStatus;

@interface H264Decoder : NSObject
@property(assign,nonatomic)H264DecoderStatus status;
- (instancetype)initWithUrl:(NSString*)url;
-(BOOL)start;
-(void)stop;
@end
