//
//  PLFAVPlayerManager.h
//  XSSYH
//
//  Created by ccia on 2019/6/15.
//  Copyright © 2019 ccia. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^MusicPlayingBlock)(CGFloat totalTime, CGFloat currentTime);

NS_ASSUME_NONNULL_BEGIN

@interface PLFAVPlayerManager : NSObject

/**  暂停  */
- (void)pause;

/**  开始  */
- (void)start;

/**  停止  */
- (void)stop;

/**  是否在播放中  */
- (BOOL)isPlaying;

/**  上一首  */
- (void)lastMusic;

/**  下一首  */
- (void)nextMusic;

///**  准备播放（缓冲）  */
//- (BOOL)perpareToPlay;

/**  获取当前播放音频的总时长  */
- (CGFloat)getMusicTotalTime;

/**  跳到指定位置  */
- (void)jumpTheOrderTime:(CGFloat)value;

- (void)playWithUrl:(NSString *)url;

/**  当前播放时长  */
@property (nonatomic, assign) CGFloat currentTime;

/**  开始播放时间点  */
@property (nonatomic, assign) CGFloat startTime;

- (void)playWithMusicArray:(NSMutableArray *)musicArray;
+ (instancetype)shareManager;
@property (nonatomic, copy) MusicPlayingBlock musicPlayBlock;

/**  资源是否加载成功  */
@property (nonatomic, assign) BOOL isPerpareToPlay;

@end

NS_ASSUME_NONNULL_END
