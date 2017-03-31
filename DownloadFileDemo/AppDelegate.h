//
//  AppDelegate.h
//  DownloadFileDemo
//
//  Created by bigliang on 2017/3/30.
//  Copyright © 2017年 5i5j. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^MyBlock)();

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic)MyBlock backgroundSessionCompletionHandler;


@end

