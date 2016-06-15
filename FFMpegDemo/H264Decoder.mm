//
//  H264Decoder.m
//  FFMpegDemo
//
//  Created by tongguan on 16/6/15.
//  Copyright © 2016年 MinorUncle. All rights reserved.
//

#import "H264Decoder.h"
#import "avformat.h"
#import "GJQueue.h"
@interface H264Decoder()
{
    NSString* _fileUrl;
    AVFormatContext *_formatContext;
    AVCodec* _videoDecoder;
    AVCodecContext* _videoDecoderContext;
    
    AVCodec* _audioDecoder;
    AVCodecContext* _audioDecoderContext;
    dispatch_queue_t _videoDecodeQueue;
}
@end
@implementation H264Decoder
- (instancetype)initWithUrl:(NSString*)url
{
    self = [super init];
    if (self) {
        av_register_all();
    }
    return self;
}
-(void)_init{
    _formatContext = avformat_alloc_context();
    int result = avformat_open_input(&_formatContext, _fileUrl.UTF8String, NULL, NULL);
    [self showErrWidhCode:result preStr:@"avformat_open_input"];

    result = avformat_find_stream_info(_formatContext, NULL);
    [self showErrWidhCode:result preStr:@"avformat_find_stream_info"];

    BOOL fristFind = NO;
    for (int i = 0; _formatContext->nb_streams; i++) {
        if (_videoDecoder == NULL && _formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            _videoDecoder = avcodec_find_decoder(_formatContext->streams[i]->codecpar->codec_id);
            if (_videoDecoder == NULL) {
                NSLog(@"avcodec_find_decoder err");
            }
            _videoDecoderContext = _formatContext->streams[i]->codec;
            if (!fristFind) {
                fristFind = YES;
            }else{
                break;
            }
        }
        if (_audioDecoder == NULL && _formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            _audioDecoder = avcodec_find_decoder(_formatContext->streams[i]->codecpar->codec_id);
            if (_audioDecoder == NULL) {
                NSLog(@"avcodec_find_decoder err");
            }
            _audioDecoderContext = _formatContext->streams[i]->codec;
            if (!fristFind) {
                fristFind = YES;
            }else{
                break;
            }
        }
    }
}
-(BOOL)start{
    int result = avcodec_open2(_videoDecoderContext, _videoDecoder, NULL);
    result *= avcodec_open2(_audioDecoderContext, _audioDecoder, NULL);
    if (result != 0) {
        [self showErrWidhCode:result preStr:@"avformat_find_stream_info"];
        return NO;
    }
    AVPacket* videoPacket;
    AVFrame* _frame;
    _status = H264DecoderPlaying;
    _videoDecodeQueue = dispatch_queue_create("vidoeDecode", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(_videoDecodeQueue, ^{
        do {
            int result = av_read_frame(_formatContext, videoPacket);
            [self showErrWidhCode:result preStr:@"av_read_frame"];
            result = avcodec_send_packet(_videoDecoderContext, videoPacket);
            [self showErrWidhCode:result preStr:@"avcodec_send_packet"];
        } while (result && _status == H264DecoderPlaying);
    });
    return YES;
}
-(void)stop{
    _status = H264DecoderStopped;
}

-(void)showErrWidhCode:(int)errorCode preStr:(NSString*)preStr{
    char* c = (char*)&errorCode;
    if (errorCode <0 ) {
        NSString* err;
        if (errorCode == AVERROR(EAGAIN)) {
            err = @"EAGAIN";
        }else if(errorCode == AVERROR(EINVAL)){
            err = @"EINVAL";
        }else if (errorCode == AVERROR_EOF){
            err = @"AVERROR_EOF";
        }else if (errorCode == AVERROR(ENOMEM)){
            err = @"AVERROR(ENOMEM)";
        }
        if (preStr == nil) {
            preStr = @"";
        }
        NSLog(@"%@:%c%c%c%c error:%@",preStr,c[3],c[2],c[1],c[0],err);
    }else{
        NSLog(@"%@成功",preStr);
    }

}

@end
