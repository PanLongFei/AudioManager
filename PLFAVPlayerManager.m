//
//  PLFAVPlayerManager.m
//  XSSYH
//
//  Created by ccia on 2019/6/15.
//  Copyright © 2019 ccia. All rights reserved.
//

#import "PLFAVPlayerManager.h"
#import <AVFoundation/AVFoundation.h>



@interface PLFAVPlayerManager ()<AVAssetResourceLoaderDelegate>

/**  播放器  */
//@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) NSMutableArray *musicArr;

@property (nonatomic, strong) id timeObserver;
//正在播放第几个
@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) BOOL hasObserver;


@property (nonatomic, strong) AVAssetResourceLoader *resourceLoader;
@end

@implementation PLFAVPlayerManager

+ (instancetype)shareManager{
    static PLFAVPlayerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PLFAVPlayerManager alloc] init];
        manager.index = 0;
        manager.hasObserver = NO;
        manager.musicArr = [NSMutableArray array];
    });
    return manager;
}

/**  播放音频 */
-(void)playWithMusicArray:(NSMutableArray *)musicArray {
    
    [self.musicArr addObjectsFromArray:musicArray];
    [self playWithUrl:musicArray[0]];
}

- (void)playWithUrl:(NSString *)url {
    self.isPerpareToPlay = NO;
    [self removeObserver];
    NSURL *musicUrl = [NSURL URLWithString:url];
//    AVURLAsset *assetUrl = [AVURLAsset assetWithURL:musicUrl];
//    [assetUrl.resourceLoader setDelegate:self queue:dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    //创建播放器
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:musicUrl];
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:assetUrl];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self start];
    [self addObserver];
}

//开始
- (void)start {
    
    [self.player play];
}

//获取音频总时长
- (CGFloat)getMusicTotalTime {
   return  CMTimeGetSeconds(self.player.currentItem.duration);
}

//停止
- (void)stop {
    [self.player pause];
    [self removeObserver];
    self.player = nil;
    self.index = 0;
    [self.musicArr removeAllObjects];
    
}

//暂停
- (void)pause {
    [self.player pause];
    //播放时长
//    self.currentTime = self.playerItem.currentTime.value;
}

- (void)lastMusic {
    //判断是否为第一首
    if (self.index == 0) {
        self.index = self.musicArr.count - 1;
    }else {
        self.index--;
    }
    NSString *musicURL = self.musicArr[self.index];
    [self playWithUrl:musicURL];
}


- (void)nextMusic {
    //判断是否为最后一首
    if (self.index == self.musicArr.count - 1) {
        self.index = 0;
    }else {
        self.index++;
    }
    NSString *musicURL = self.musicArr[self.index];
    [self playWithUrl:musicURL];
}

- (void)setStartTime:(CGFloat)startTime {
    _startTime = startTime;
    [self.player seekToTime:CMTimeMake(startTime, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
}

- (void)jumpTheOrderTime:(CGFloat)value {
    [self.player seekToTime:CMTimeMake(value, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

//添加监听
- (void)addObserver {
    if (!self.hasObserver) {
        self.hasObserver = YES;
        //KVO监听status属性变化
        [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //播放过程中进度改变
        [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        kWeakSelf;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            weakself.musicPlayBlock([weakself getMusicTotalTime], CMTimeGetSeconds(time));
        }];
        //监听播放完毕
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(musicPlayEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
}


//移除监听
- (void)removeObserver {
    if (self.hasObserver) {
        self.hasObserver = NO;
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
}

- (void)dealloc {
    [self.player pause];
    self.player = nil;
    [self removeObserver];
}

- (void)musicPlayEnd:(NSNotification *)notification {
//    [self nextMusic];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
//    CGFloat musicTime = [self getMusicTotalTime];
//    NSDictionary *userInfo = @{@"musicTime" : [NSString stringWithFormat:@"%f",musicTime]};
    [center postNotificationName:kNotificationMusicPlayEnd object:nil userInfo:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        //播放器状态
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        switch (status) {
            case AVPlayerItemStatusUnknown: {
                XYLog(@"播放音频未知错误");
                //未知错误
                break;
            }
            case AVPlayerItemStatusFailed: {
                //资源有误
                XYLog(@"播放音频资源有误");
                break;
            }
            case AVPlayerItemStatusReadyToPlay: {
                XYLog(@"播放音频资源加载成功");
                self.isPerpareToPlay = YES;
                [self.player play];
                [self sendMusicPerpareToPlay];
            }
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = self.player.currentItem.loadedTimeRanges;
        // 本次缓冲的时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        // 缓冲总长度
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        // 音乐的总时间
        NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
        // 计算缓冲百分比例
        NSTimeInterval scale = totalBuffer / duration;
        XYLog(@"%f",scale);
    }
}

//发送已经准备完毕通知
- (void)sendMusicPerpareToPlay {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    CGFloat musicTime = [self getMusicTotalTime];
    NSDictionary *userInfo = @{@"musicTime" : [NSString stringWithFormat:@"%f",musicTime]};
    [center postNotificationName:kNotificationMusicPerpareToPlay object:nil userInfo:userInfo];
}



#pragma mark AVAssetResourceLoaderDelegate



- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}



@end
