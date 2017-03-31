//
//  ViewController.m
//  DownloadFileDemo
//
//  Created by bigliang on 2017/3/30.
//  Copyright © 2017年 5i5j. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>
#import <Masonry.h>
#import <UIView+Toast.h>
#import "DownloadFileUtil.h"
#import "AppDelegate.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

static NSString *const bl_downloadUrl = @"http://sw.bos.baidu.com/sw-search-sp/software/78ff35549b3e6/QQ_mac_5.5.0.dmg";

@interface ViewController ()<DownloadFileUtilDelegate>

@property (nonatomic, strong)UILabel          *progressLabel;
@property (nonatomic, strong)UIButton         *downloadButton;
@property (nonatomic, strong)UIButton         *stopButton;
@property (nonatomic, strong)UIButton         *continueButton;
@property (nonatomic, strong)DownloadFileUtil *downloadFileUtil;
@property (nonatomic, strong)UILabel          *infoLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self bl_initData];
    [self bl_addViews];
}

- (void)bl_initData
{
    RAC(self.downloadButton,enabled) = [[[RACObserve(self.downloadFileUtil, isDownloading) deliverOnMainThread] flattenMap:^RACStream *(id value) {
        return [RACSignal return:@(![value boolValue])];
    }] takeUntil:self.rac_willDeallocSignal];
}

- (void)bl_addViews
{
    [self.view addSubview:self.infoLabel];
    [self.view addSubview:self.progressLabel];
    [self.view addSubview:self.downloadButton];
    [self.view addSubview:self.stopButton];
    [self.view addSubview:self.continueButton];
    [self bl_makeConstraints];
}

- (void)bl_makeConstraints
{
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(kScreenWidth);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view.mas_top).offset(50);
    }];
    
    [self.progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(kScreenWidth);
        make.height.mas_equalTo(40);
        make.center.mas_equalTo(self.view);
    }];
    
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(self.progressLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(kScreenWidth/3);
        make.left.mas_equalTo(self.view.mas_left);
    }];
    
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.centerY.mas_equalTo(self.downloadButton);
        make.width.mas_equalTo(kScreenWidth/3);
        make.left.mas_equalTo(self.downloadButton.mas_right);
    }];
    
    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.centerY.mas_equalTo(self.downloadButton);
        make.width.mas_equalTo(kScreenWidth/3);
        make.left.mas_equalTo(self.stopButton.mas_right);
    }];
}

#pragma mark DownloadFileUtilDelegate'delegate

- (void)downloadFileUtil:(DownloadFileUtil *)downloadFileUtil didDownloadProgress:(float)progress
{
    NSLog(@"%f",progress);
    self.progressLabel.text = [NSString stringWithFormat:@"已下载:%.2f",progress];
}

- (void)downloadFileUtil:(DownloadFileUtil *)downloadFileUtil didCompleteWithError:(NSError *)error
{
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.infoLabel.text = [NSString stringWithFormat:@"%ld",error.code];
        });
    }else{
        double progress = (double)downloadFileUtil.downloadTask.countOfBytesReceived / (double)downloadFileUtil.downloadTask.countOfBytesExpectedToReceive;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"已下载:%.2f",100.0 * progress];
        });
    }
}

- (void)downloadFileUtilDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"back");
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
}

#pragma mark - getter

- (UILabel *)progressLabel
{
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc]init];
        _progressLabel.text = @"等待下载...";
        _progressLabel.textColor = [UIColor blueColor];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _progressLabel;
}

- (UIButton *)downloadButton
{
    if (!_downloadButton) {
        _downloadButton = [[UIButton alloc]init];
        [_downloadButton setBackgroundColor:[UIColor blueColor]];
        [_downloadButton setTitle:@"下载" forState:UIControlStateNormal];
        [[_downloadButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(UIButton *btn) {
            [self.downloadFileUtil startDownloadAtUrl:bl_downloadUrl];
        }];
    }
    return _downloadButton;
}

- (UIButton *)stopButton
{
    if (!_stopButton) {
        _stopButton = [[UIButton alloc]init];
        [_stopButton setBackgroundColor:[UIColor redColor]];
        [_stopButton setTitle:@"暂停" forState:UIControlStateNormal];
        @weakify(self);
        [[_stopButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(UIButton *btn) {
            @strongify(self);
            [self.downloadFileUtil stopDownload];
        }];
    }
    return _stopButton;
}

- (UIButton *)continueButton
{
    if (!_continueButton) {
        _continueButton = [[UIButton alloc]init];
        [_continueButton setBackgroundColor:[UIColor greenColor]];
        [_continueButton setTitle:@"继续" forState:UIControlStateNormal];
        [[_continueButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(UIButton *btn) {
            [self.downloadFileUtil startDownloadAtUrl:bl_downloadUrl];
        }];
    }
    return _continueButton;
}

- (UILabel *)infoLabel
{
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc]init];
    }
    return _infoLabel;
}

- (DownloadFileUtil *)downloadFileUtil
{
    if (!_downloadFileUtil) {
        _downloadFileUtil = [[DownloadFileUtil alloc]init];
        _downloadFileUtil.delegate = self;
    }
    return _downloadFileUtil;
}

@end
