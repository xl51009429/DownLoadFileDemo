//
//  DownloadFileUtil.m
//  DownloadFileDemo
//
//  Created by bigliang on 2017/3/31.
//  Copyright © 2017年 5i5j. All rights reserved.
//

#import "DownloadFileUtil.h"
#import <UIKit/UIKit.h>

@interface DownloadFileUtil ()<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong)NSData                              *resumeData;
@property (nonatomic, strong)NSURLSession                        *session;
@property (nonatomic, strong)NSString                            *url;
@property (nonatomic, strong, readwrite)NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign, readwrite)BOOL                      isDownloading;

@end

@implementation DownloadFileUtil

- (instancetype)initWithDownloadingToURL:(NSString *)url
{
    if (self = [super init]) {
        self.downloadToUrl = url;
    }
    return self;
}

//获取NSURLSessionResumeCurrentRequest和NSURLSessionResumeOriginalRequest
- (NSData *)getCorrectResumeData:(NSData *)resumeData {
    NSData *newData = nil;
    NSString *kResumeCurrentRequest = @"NSURLSessionResumeCurrentRequest";
    NSString *kResumeOriginalRequest = @"NSURLSessionResumeOriginalRequest";
    //获取继续数据的字典
    NSMutableDictionary* resumeDictionary = [NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListMutableContainers format:NULL error:nil];
    //重新编码原始请求和当前请求
    resumeDictionary[kResumeCurrentRequest] = [self correctRequestData:resumeDictionary[kResumeCurrentRequest]];
    resumeDictionary[kResumeOriginalRequest] = [self correctRequestData:resumeDictionary[kResumeOriginalRequest]];
    newData = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainers error:nil];
    
    return newData;
}

//单个获取NSURLSessionResumeCurrentRequest和NSURLSessionResumeOriginalRequest
- (NSData *)correctRequestData:(NSData *)data {
    NSData *resultData = nil;
    NSData *arData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (arData != nil) {
        return data;
    }
    
    NSMutableDictionary *archiveDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    
    int k = 0;
    NSMutableDictionary *oneDict = [NSMutableDictionary dictionaryWithDictionary:archiveDict[@"$objects"][1]];
    while (oneDict[[NSString stringWithFormat:@"$%d", k]] != nil) {
        k += 1;
    }
    
    int i = 0;
    while (oneDict[[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]] != nil) {
        NSString *obj = oneDict[[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
        if (obj != nil) {
            [oneDict setObject:obj forKey:[NSString stringWithFormat:@"$%d", i + k]];
            [oneDict removeObjectForKey:obj];
            archiveDict[@"$objects"][1] = oneDict;
        }
        i += 1;
    }
    
    if (oneDict[@"__nsurlrequest_proto_props"] != nil) {
        NSString *obj = oneDict[@"__nsurlrequest_proto_props"];
        [oneDict setObject:obj forKey:[NSString stringWithFormat:@"$%d", i + k]];
        [oneDict removeObjectForKey:@"__nsurlrequest_proto_props"];
        archiveDict[@"$objects"][1] = oneDict;
    }
    
    NSMutableDictionary *twoDict = [NSMutableDictionary dictionaryWithDictionary:archiveDict[@"$top"]];
    if (twoDict[@"NSKeyedArchiveRootObjectKey"] != nil) {
        [twoDict setObject:twoDict[@"NSKeyedArchiveRootObjectKey"] forKey:[NSString stringWithFormat:@"%@", NSKeyedArchiveRootObjectKey]];
        [twoDict removeObjectForKey:@"NSKeyedArchiveRootObjectKey"];
        archiveDict[@"$top"] = twoDict;
    }
    
    resultData = [NSPropertyListSerialization dataWithPropertyList:archiveDict format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainers error:nil];
    
    return resultData;
}

- (void)startDownloadAtUrl:(NSString *)url
{
    if (!self.isDownloading) {
        self.url = url;
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSLog(@"%@",cachesPath);
        if (self.resumeData) {
            self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
            [self.downloadTask resume];
            self.resumeData = nil;
        }else{
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"bl_isDownloading"]) {
                NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"bl_backgroundSessionConfiguration"];
                _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
                return;
            }
            self.downloadTask = [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet]]]];
            [self.downloadTask resume];
        }
        self.isDownloading = YES;
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"bl_isDownloading"];
    }
}

//暂停任务
- (void)stopDownload
{
    if (self.downloadTask) {
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"bl_isDownloading"];
        [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            
        }];
    }
}


#pragma mark - life cycle

- (void)dealloc
{
    if (self.downloadTask) {
        [self.downloadTask cancel];
    }
}

#pragma mark - NSURLSessionDelegate'delegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(downloadFileUtil:didDownloadProgress:)]) {
            [self.delegate downloadFileUtil:self didDownloadProgress:(100.0 * totalBytesWritten / totalBytesExpectedToWrite)];
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (!self.downloadToUrl) {
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:self.url.lastPathComponent];
        self.downloadToUrl = path;
    }
    NSError *error;
    BOOL isSuccess = [manager moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.downloadToUrl] error:&error];
    if (!isSuccess) {
        NSLog(@"error:%@",error);
    }
    self.isDownloading = NO;
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"bl_isDownloading"];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]){
            self.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //iOS10 对resumeData进行处理
            if ([UIDevice currentDevice].systemVersion.doubleValue >= 10.0) {
                self.resumeData = [self getCorrectResumeData:self.resumeData];
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"bl_isDownloading"]) {
                self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
                [self.downloadTask resume];
                self.resumeData = nil;
            }
        }

    }
    if ([self.delegate respondsToSelector:@selector(downloadFileUtil:didCompleteWithError:)]) {
        [self.delegate downloadFileUtil:self didCompleteWithError:error];
    }
    self.isDownloading = NO;
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"bl_isDownloading"];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if ([self.delegate respondsToSelector:@selector(downloadFileUtilDidFinishEventsForBackgroundURLSession:)]) {
        [self.delegate downloadFileUtilDidFinishEventsForBackgroundURLSession:session];
    }
}

#pragma mark - getter

- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"bl_backgroundSessionConfiguration"];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _session;
}


@end
