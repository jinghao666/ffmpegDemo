/**
 * 最简单的基于FFmpeg的视频解码器-IOS
 * Simplest FFmpeg IOS Decoder
 *
 * 雷霄骅 Lei Xiaohua
 * leixiaohua1020@126.com
 * 中国传媒大学/数字电视技术
 * Communication University of China / Digital TV Technology
 * http://blog.csdn.net/leixiaohua1020
 *
 * 本程序是IOS平台下最简单的基于FFmpeg的视频解码器。
 * 它可以将输入的视频数据解码成YUV像素数据。
 *
 * This software is the simplest decoder based on FFmpeg in IOS.
 * It can decode video stream to raw YUV data.
 *
 */

#import "ViewController.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/imgutils.h"
#include "libswscale/swscale.h"
#import "OpenGLView20.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *outputurl;
@property (weak, nonatomic) IBOutlet UITextField *inputurl;
@property (weak, nonatomic) IBOutlet OpenGLView20 *openglView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self allFormat];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)allFormat{
    char info[40000] = { 0 };
    
    av_register_all();
   // avformat_network_init();

    AVInputFormat *if_temp = av_iformat_next(NULL);
    AVOutputFormat *of_temp = av_oformat_next(NULL);
    //Input
    while(if_temp!=NULL){
        sprintf(info, "%s[In ]%10s\n", info, if_temp->name);
        if_temp=if_temp->next;
    }
    //Output
    while (of_temp != NULL){
        sprintf(info, "%s[Out]%10s\n", info, of_temp->name);
        of_temp = of_temp->next;
    }
    //printf("%s", info);
    NSString * info_ns = [NSString stringWithFormat:@"%s", info];
    NSLog(@"format:%@",info_ns);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


int height,width;
- (IBAction)clickDecodeButton:(id)sender {
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self decode];
});
}
-(void)newDecode{
    AVFormatContext *context;
    AVCodec* codec;
    AVCodecContext* codecCon;
    AVPacket* packet;
    AVFrame* frame;
    
    NSString *input_nsstr=[[NSBundle mainBundle]pathForResource:@"1" ofType:@"mp4"];
    NSString *output_nsstr=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
                                                               , NSUserDomainMask
                                                               , YES)[0];
    output_nsstr = [output_nsstr stringByAppendingPathComponent:@"2.yvu"];
    int result = avformat_open_input(&context, input_nsstr.UTF8String, NULL, NULL);
    if (result != 0) {
        NSLog(@"avformat_open_input error:%d",result);
    }
    result = avformat_find_stream_info(context, NULL);
    if (result != 0) {
        NSLog(@"avformat_find_stream_info error:%d",result);
    }
    for (int i = 0; context->nb_streams; i++) {
        if (context->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            codec = avcodec_find_decoder(context->streams[i]->codecpar->codec_id);
            if (codec == NULL) {
                NSLog(@"avcodec_find_decoder err");

            }
            break;
        }
    }
    codecCon = avcodec_alloc_context3(codec);
    avcodec_open2(codecCon, codec, NULL);
    packet =av_packet_alloc();
    frame = av_frame_alloc();
    avcodec_send_packet(codecCon, <#const AVPacket *avpkt#>)
    
    
    
}
-(void)decode{
    AVFormatContext	*pFormatCtx;
    int				i, videoindex;
    AVCodecContext	*pCodecCtx;
    AVCodec			*pCodec;
    AVFrame	*pFrame,*pFrameYUV;
    uint8_t *out_buffer;
    AVPacket *packet;
    int y_size;
    int ret, got_picture;
    struct SwsContext *img_convert_ctx;
    FILE *fp_yuv;
    int frame_cnt;
    clock_t time_start, time_finish;
    double  time_duration = 0.0;
    
    char input_str_full[500]={0};
    char output_str_full[500]={0};
    char info[1000]={0};
    
//    NSString *input_str= [NSString stringWithFormat:@"resource.bundle/%@",self.inputurl.text];
//    NSString *output_str= [NSString stringWithFormat:@"resource.bundle/%@",self.outputurl.text];
//
    
    NSString *input_nsstr=[[NSBundle mainBundle]pathForResource:@"1" ofType:@"mp4"];
    NSString *output_nsstr=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
                                        , NSUserDomainMask
                                        , YES)[0];
    output_nsstr = [output_nsstr stringByAppendingPathComponent:@"2.yvu"];
    sprintf(input_str_full,"%s",[input_nsstr UTF8String]);
    sprintf(output_str_full,"%s",[output_nsstr UTF8String]);
    
    printf("Input Path:%s\n",input_str_full);
    printf("Output Path:%s\n",output_str_full);
    
    pFormatCtx = avformat_alloc_context();
    int result =0;
    if((result = avformat_open_input(&pFormatCtx,input_str_full,NULL,NULL))!=0){
        printf("Couldn't open input stream:%d.\n",result);
        return ;
    }
    if(avformat_find_stream_info(pFormatCtx,NULL)<0){
        printf("Couldn't find stream information.\n");
        return;
    }
    videoindex=-1;
    for(i=0; i<pFormatCtx->nb_streams; i++)
        if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    if(videoindex==-1){
        printf("Couldn't find a video stream.\n");
        return;
    }
    pCodecCtx=pFormatCtx->streams[videoindex]->codec;
    pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL){
        printf("Couldn't find Codec.\n");
        return;
    }
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        printf("Couldn't open codec.\n");
        return;
    }
    
    pFrame=av_frame_alloc();
    pFrameYUV=av_frame_alloc();
    height = pCodecCtx->height;
    width = pCodecCtx->width;
    
    out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P,  width, height,1));
    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize,out_buffer,
                         AV_PIX_FMT_YUV420P,width, height,1);
    packet=(AVPacket *)av_malloc(sizeof(AVPacket));
    
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                     pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
    
//    sprintf(info,   "[Input     ]%s\n", [input_str UTF8String]);
//    sprintf(info, "%s[Output    ]%s\n",info,[output_str UTF8String]);
    sprintf(info, "%s[Format    ]%s\n",info, pFormatCtx->iformat->name);
    sprintf(info, "%s[Codec     ]%s\n",info, pCodecCtx->codec->name);
    sprintf(info, "%s[Resolution]%dx%d\n",info, pCodecCtx->width,pCodecCtx->height);
    
    
    fp_yuv=fopen(output_str_full,"wb+");
    if(fp_yuv==NULL){
        printf("Cannot open output file.\n");
        return;
    }
    
    frame_cnt=0;
    time_start = clock();
    while(av_read_frame(pFormatCtx, packet)>=0){
        if(packet->stream_index==videoindex){
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
            if(ret < 0){
                printf("Decode Error.\n");
                return;
            }
            if(got_picture){
                sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                          pFrameYUV->data, pFrameYUV->linesize);
                
                y_size=pCodecCtx->width*pCodecCtx->height;
                void *data = malloc(y_size*1.5);
                memcpy(data, pFrameYUV->data[0], y_size);
                memcpy(data+y_size, pFrameYUV->data[1], y_size/4.0);
                memcpy(data+y_size+y_size/4, pFrameYUV->data[2], y_size/4.0);

//
//                fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
//                fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
//                fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
                [self.openglView displayYUV420pData:data width:pCodecCtx->width height:pCodecCtx->height];
                //Output info
                char pictype_str[10]={0};
                switch(pFrame->pict_type){
                    case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
                    case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
                    case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
                    default:sprintf(pictype_str,"Other");break;
                }
                printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
                frame_cnt++;
                free(data);
            }
        }
        av_free_packet(packet);
    }
    //flush decoder
    //FIX: Flush Frames remained in Codec
    while (1) {
        ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
        if (ret < 0)
            break;
        if (!got_picture)
            break;
        sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                  pFrameYUV->data, pFrameYUV->linesize);
        int y_size=pCodecCtx->width*pCodecCtx->height;
        fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
        fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
        fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
        //Output info
        char pictype_str[10]={0};
        switch(pFrame->pict_type){
            case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
            case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
            case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
            default:sprintf(pictype_str,"Other");break;
        }
        printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
        frame_cnt++;
    }
    time_finish = clock();
    time_duration=(double)(time_finish - time_start);
    
    sprintf(info, "%s[Time      ]%fus\n",info,time_duration);
    sprintf(info, "%s[Count     ]%d\n",info,frame_cnt);
    
    sws_freeContext(img_convert_ctx);
    
    fclose(fp_yuv);
    
    av_frame_free(&pFrameYUV);
    av_frame_free(&pFrame);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
    
    NSString * info_ns = [NSString stringWithFormat:@"%s", info];
    
}

- (IBAction)clickEncodeButton:(id)sender {
    NSString *input_nsstr=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
                                                               , NSUserDomainMask
                                                               , YES)[0];
    input_nsstr = [input_nsstr stringByAppendingPathComponent:@"2.yvu"];
    AVFormatContext* formatContext ;
    avformat_alloc_output_context2(&formatContext,NULL,NULL,"ds.h264");
    if (avformat_open_input(&formatContext, input_nsstr.UTF8String, NULL, NULL) <=0) {
        printf("文件打开失败");
    }
    

}


@end