//
//  DownloadFileUtil.h
//  DownloadFileDemo
//
//  Created by bigliang on 2017/3/31.
//  Copyright © 2017年 5i5j. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadFileUtil;

@protocol DownloadFileUtilDelegate <NSObject>

- (void)downloadFileUtil:(DownloadFileUtil *)downloadFileUtil didDownloadProgress:(float)progress;
- (void)downloadFileUtil:(DownloadFileUtil *)downloadFileUtil didCompleteWithError:(NSError *)error;
- (void)downloadFileUtilDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

@interface DownloadFileUtil : NSObject

@property (nonatomic, strong)NSString                    *downloadToUrl;
@property (nonatomic, assign)id<DownloadFileUtilDelegate> delegate;
@property (nonatomic, strong, readonly)NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign, readonly)BOOL isDownloading;

- (instancetype)initWithDownloadingToURL:(NSString *)url;
- (void)startDownloadAtUrl:(NSString *)url;
- (void)stopDownload;

@end
