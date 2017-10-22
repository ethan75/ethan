//
//  ViewController.m
//  MusicPlayer
//
//  Created by administrator on 2017/9/22.
//  Copyright © 2017年 JohnLai. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import "UIColor+Tools.h"
#import "Masonry.h"

/***设备视图适配***/
#define FIT_W [UIScreen mainScreen].bounds.size.width / 375
#define FIT_H [UIScreen mainScreen].bounds.size.height / 667
@interface ViewController (){
    //__block BOOL _isSliderTouch;
    BOOL _isPlaying;
    float _total; //总时间
}

@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,weak) UIImageView *musicImageView;
@property (nonatomic,weak) UIButton *playButton;
@property (nonatomic,weak) UILabel *beginTimeLabel;
@property (nonatomic,weak) UILabel *endTimeLabel;
@property (nonatomic,weak) UISlider *progressSlider;
@property (nonatomic,assign) __block BOOL isSliderTouch;

@end

@implementation ViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"f2f2f2"];
    [self createUI];
}

- (void)createUI{
    __weak typeof(self) weakSelf = self;
    CGFloat imageViewWidth = 375 *FIT_W * .7;
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"床边故事.jpg"]];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = imageViewWidth /2;
    imageView.clipsToBounds = YES;
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.view.mas_centerY).offset(-80*FIT_H);
        make.centerX.equalTo(weakSelf.view);
        make.width.height.equalTo(@(imageViewWidth));
    }];
    self.musicImageView = imageView;
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playButton setImage:[UIImage imageNamed:@"icon_play"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"icon_stop"] forState:UIControlStateSelected];
    [playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    [playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(imageView);
    }];
    self.playButton = playButton;
    
    UILabel *musicNameLabel = [[UILabel alloc]init];
    musicNameLabel.text = @"告白气球.mp3";
    musicNameLabel.font = [UIFont systemFontOfSize:17.f];
    musicNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:musicNameLabel];
    [musicNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.view);
        make.top.equalTo(imageView.mas_bottom).offset(30);
    }];
    
    UILabel *sizeLabel = [[UILabel alloc]init];
    sizeLabel.text = @"5.58MB";
    sizeLabel.font = [UIFont systemFontOfSize:15.f];
    sizeLabel.textAlignment = NSTextAlignmentCenter;
    sizeLabel.textColor = [UIColor grayColor];
    [self.view addSubview:sizeLabel];
    [sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.view);
        make.top.equalTo(musicNameLabel.mas_bottom).offset(10);
    }];
    
    UISlider *slider = [[UISlider alloc]init];
    slider.minimumTrackTintColor = [UIColor colorWithHexString:@"37ccff"];
    slider.maximumTrackTintColor = [UIColor colorWithHexString:@"484848"];
    [slider setThumbImage:[UIImage imageNamed:@"icon_sliderButton"] forState:UIControlStateNormal];
    slider.minimumValue = 0;
    slider.maximumValue = 1;
    slider.continuous = YES;
    [slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:slider];
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(- 40 *FIT_H);
        make.width.equalTo(@(imageViewWidth));
        make.centerX.equalTo(weakSelf.view);
    }];
    self.progressSlider = slider;
    
    UILabel *leftTimeLabel = [[UILabel alloc]init];
    leftTimeLabel.text = @"00:00";
    leftTimeLabel.textColor = [UIColor grayColor];
    leftTimeLabel.font = [UIFont systemFontOfSize:12.f];
    [self.view addSubview:leftTimeLabel];
    [leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(slider.mas_left).offset(-8);
        make.centerY.equalTo(slider);
    }];
    self.beginTimeLabel = leftTimeLabel;
    
    UILabel *rightTimeLabel = [[UILabel alloc]init];
    rightTimeLabel.text = @"00:00";
    rightTimeLabel.textColor = [UIColor grayColor];
    rightTimeLabel.font = [UIFont systemFontOfSize:12.f];
    [self.view addSubview:rightTimeLabel];
    [rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(slider.mas_right).offset(8);
        make.centerY.equalTo(slider);
    }];
    self.endTimeLabel = rightTimeLabel;
  
    [self settingPlayer];
}

- (void)settingPlayer{
    //NSURL *fileURL = [[NSBundle mainBundle]URLForResource:@"A-Lin-无人知晓的我" withExtension:@".mp3"];
    NSURL *fileURL = [NSURL URLWithString:@"http://sc1.111ttt.com:8282/2016/1/06/25/199251943186.mp3?tflag=1506086580&pin=7419411e5b5f03465014f5479af3465f"];
    
    self.playerItem = [[AVPlayerItem alloc]initWithURL:fileURL];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    
    CMTime duration = self.player.currentItem.asset.duration;
    NSTimeInterval total = CMTimeGetSeconds(duration);
    self.endTimeLabel.text = [self timeIntervalToMMSSFormat:total];
    
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {

        //更新时间和进度条
        float current = CMTimeGetSeconds(weakSelf.player.currentItem.currentTime);
        _total = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        weakSelf.beginTimeLabel.text = [weakSelf timeIntervalToMMSSFormat:CMTimeGetSeconds(time)];
        if (!weakSelf.isSliderTouch) {
            //拖动slider的时候不更新进度条
            weakSelf.progressSlider.value = current / _total;
        }
        
    }];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)playToEnd{
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.01* NSEC_PER_SEC)); dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        self.progressSlider.value = 0;
        self.playButton.selected = NO;
        self.beginTimeLabel.text = @"00:00";
        [self stopLayer:self.musicImageView.layer];
        _isPlaying = NO;
        self.player = nil;
        self.playerItem = nil;
    });
  
}

#pragma mark - 进度条状态改变
- (void)sliderTouchDown:(UISlider *)slider{
    _isSliderTouch = YES;
}

- (void)sliderValueChange:(UISlider *)slider{
    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value * _total, self.player.currentItem.currentTime.timescale)];
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.03* NSEC_PER_SEC)); dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        //不延迟执行会造成slider瞬间回弹
        _isSliderTouch = NO;
    });
    
}

#pragma mark - 图片旋转动画
//暂停layer上面的动画
- (void)pauseLayer:(CALayer*)layer{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

//继续layer上面的动画
- (void)resumeLayer:(CALayer*)layer{
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

//停止动画
- (void)stopLayer:(CALayer *)layer{
    [layer removeAnimationForKey:@"rotationAnimation"];
}

#pragma mark - Action
- (void)playButtonAction:(UIButton *)button{
    button.selected = !button.selected;
    if (!self.player) {
        [self settingPlayer];
    }
    if (button.selected) {
      [self.player play];
       _isPlaying == YES ? [self resumeLayer:self.musicImageView.layer] : [self startAnimate];
        _isPlaying = YES;
   }else{
        [self.player pause];
        [self pauseLayer:self.musicImageView.layer];
    }
}

- (void)startAnimate{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];
    rotationAnimation.speed = 1;
    rotationAnimation.duration = 25;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 9999999;
    rotationAnimation.removedOnCompletion = NO;
    [self.musicImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

#pragma mark - 设置时间数据
- (void)updateProgressLabelCurrentTime:(NSTimeInterval )currentTime duration:(NSTimeInterval )duration {
    self.beginTimeLabel.text = [self timeIntervalToMMSSFormat:currentTime];
    self.endTimeLabel.text = [self timeIntervalToMMSSFormat:duration];
   [self.progressSlider setValue:currentTime / duration animated:YES];
 
}

#pragma mark - 时间转化
- (NSString *)timeIntervalToMMSSFormat:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

@end
