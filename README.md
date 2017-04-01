## 实现原理

断点续传主要依赖于`HTTP`请求头定义的`Range`来完成。在请求时设置`Range`的值来决定请求的数据位置。例如下面：

```
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
NSString *range = [NSString stringWithFormat:@"bytes=%zd-",self.currentSize];
[request setValue:range forHTTPHeaderField:@"Range"];
```

## NSURLSession实现断点续传

NSURLSession已经实现了对Range操作的封装，简化了断点续传的难度，而且可以很简单的实现后台下载功能。下面一步步来实现基础功能。

### 1.下载

定义属性

```
@property (nonatomic, strong)NSURLSession                        *session;
@property (nonatomic, strong, readwrite)NSURLSessionDownloadTask *downloadTask;
```

初始化session

```
- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"bl_backgroundSessionConfiguration"];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _session;
}
```

通过上面方式定义的session，就可以简单的实现后台下载功能。

下面实现下载功能：

```
self.downloadTask = [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet]]]];
[self.downloadTask resume];
```
暂停下载有如下三种方式

```
//第一种：不占用系统资源，不能获取resumeData
[self.downloadTask cancel];

//第二种：不占用系统资源，可以获取resumeData，用于实现断点续传
[self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
	self.resumeData = resumeData;
}];

//第三种：挂起 占用系统资源 长时间不resume，会超时
[self.downloadTask suspend];
        
```

#### resumeData

`resumeData`记录了下载的一些信息，用于断点续传。

```
{
    NSURLSessionDownloadURL = "http://sw.bos.baidu.com/sw-search-sp/software/78ff35549b3e6/QQ_mac_5.5.0.dmg";
    
    NSURLSessionResumeBytesReceived = 2339054;
    
    NSURLSessionResumeCurrentRequest = <62706c69 73743030 d4010203 04050679 7a582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f701200 0186a0af 10190708 2c474d4e 54555657 2b583959 5a68696a 6b6c6d6e 6f707555 246e756c 6cdf101f 090a0b0c 0d0e0f10 11121314 15161718 191a1b1c 1d1e1f20 21222324 25262728 29292b2c 2d2e2f30 30292f34 2b293637 38393a3b 29293e3b 292f4243 2d455224 315f1020 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f3230 5f10205f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f32315f 10107374 61727454 696d656f 75745469 6d655f10 1e726571 75697265 7353686f 7274436f 6e6e6563 74696f6e 54696d65 6f75745f 10205f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 31305624 636c6173 735f1020 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f3131 5f10205f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f31325f 10205f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 31335f10 1a5f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f70735f 10205f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 31345f10 205f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f31 355f101a 7061796c 6f616454 72616e73 6d697373 696f6e54 696d656f 75745f10 205f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f31 365f1014 616c6c6f 77656450 726f746f 636f6c54 79706573 5f10205f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f31375f 10205f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 31385224 305f1020 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f3139 5f101f5f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f395f10 1f5f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f38 5f101f5f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f375f10 1f5f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f36 5f101f5f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f355f10 1f5f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f34 5f101f5f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f335224 325f101f 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f315f 101f5f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 305f101f 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f3210 09800080 00230000 00000000 00000880 02801880 07800a80 0a800080 07800b80 00100080 0c800d10 02800e80 08800080 00800980 08800080 07101680 03800280 0608d348 0f49294b 4c574e53 2e626173 655b4e53 2e72656c 61746976 65800080 0580045f 104c6874 74703a2f 2f73772e 626f732e 62616964 752e636f 6d2f7377 2d736561 7263682d 73702f73 6f667477 6172652f 37386666 33353534 39623365 362f5151 5f6d6163 5f352e35 2e302e64 6d67d24f 5051525a 24636c61 73736e61 6d655824 636c6173 73657355 4e535552 4ca25153 584e534f 626a6563 7423404e 00000000 00001000 09100413 ffffffff ffffffff 53474554 d35b5c0f 5d626757 4e532e6b 6579735a 4e532e6f 626a6563 7473a45e 5f606180 0f801080 118012a4 63646566 80138014 80158016 80175a55 7365722d 4167656e 74564163 63657074 5f100f41 63636570 742d4c61 6e677561 67655f10 0f416363 6570742d 456e636f 64696e67 5f103244 6f776e6c 6f616446 696c6544 656d6f2f 31204346 4e657477 6f726b2f 3830382e 312e3420 44617277 696e2f31 362e302e 30532a2f 2a557a68 2d636e5d 677a6970 2c206465 666c6174 65d24f50 71725f10 134e534d 75746162 6c654469 6374696f 6e617279 a3737453 5f10134e 534d7574 61626c65 44696374 696f6e61 72795c4e 53446963 74696f6e 617279d2 4f507677 5c4e5355 524c5265 71756573 74a27853 5c4e5355 524c5265 71756573 745f100f 4e534b65 79656441 72636869 766572d1 7b7c5f10 1b4e534b 65796564 41726368 69766552 6f6f744f 626a6563 744b6579 80010008 0011001a 0023002d 00320037 00530059 009a009d 00c000e3 00f60117 013a0141 01640187 01aa01c7 01ea020d 022a024d 02640287 02aa02ad 02d002f2 03140336 0358037a 039c03be 03c103e3 04050427 0429042b 042d0436 04370439 043b043d 043f0441 04430445 04470449 044b044d 044f0451 04530455 04570459 045b045d 045f0461 04630465 04670469 046a0471 04790485 04870489 048b04da 04df04ea 04f304f9 04fc0505 050e0510 05110513 051c0520 0527052f 053a053f 05410543 05450547 054c054e 05500552 05540556 05610568 057a058c 05c105c5 05cb05d9 05de05f4 05f8060e 061b0620 062d0630 063d064f 06520670 00000000 00000201 00000000 0000007d 00000000 00000000 00000000 00000672>;
    
    NSURLSessionResumeEntityTag = "\"afda885a630e48ae4a3bedd3d0bc7094\"";
    
    NSURLSessionResumeInfoTempFileName = "CFNetworkDownload_Occ2S2.tmp";
    
    NSURLSessionResumeInfoVersion = 2;
    
    NSURLSessionResumeOriginalRequest = <62706c69 73743030 d4010203 04050650 51582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f701200 0186a0ac 0708243b 41424849 4a234b4c 55246e75 6c6cdf10 19090a0b 0c0d0e0f 10111213 14151617 18191a1b 1c1d1e1f 20212223 24252627 28282a27 2c232d2e 2f2a2a27 2f2a2736 37253952 24315f10 10737461 72745469 6d656f75 7454696d 655f101e 72657175 69726573 53686f72 74436f6e 6e656374 696f6e54 696d656f 75745f10 205f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f31 30562463 6c617373 5f10205f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f31315f 10205f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 31325f10 205f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f31 335f101a 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 70735f10 205f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f31 345f1020 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f3135 5f101a70 61796c6f 61645472 616e736d 69737369 6f6e5469 6d656f75 745f1014 616c6c6f 77656450 726f746f 636f6c54 79706573 5224305f 101f5f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 395f101f 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f385f 101f5f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 375f101f 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f365f 101f5f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 355f101f 5f5f6e73 75726c72 65717565 73745f70 726f746f 5f70726f 705f6f62 6a5f345f 101f5f5f 6e737572 6c726571 75657374 5f70726f 746f5f70 726f705f 6f626a5f 33522432 5f101f5f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f315f10 1f5f5f6e 7375726c 72657175 6573745f 70726f74 6f5f7072 6f705f6f 626a5f30 5f101f5f 5f6e7375 726c7265 71756573 745f7072 6f746f5f 70726f70 5f6f626a 5f321009 23000000 00000000 00088002 800b8007 80098009 80008007 800a1000 10028008 80008000 80078008 80008007 10108003 80028006 08d33c0d 3d2a3f40 574e532e 62617365 5b4e532e 72656c61 74697665 80008005 80045f10 4c687474 703a2f2f 73772e62 6f732e62 61696475 2e636f6d 2f73772d 73656172 63682d73 702f736f 66747761 72652f37 38666633 35353439 62336536 2f51515f 6d61635f 352e352e 302e646d 67d24344 45465a24 636c6173 736e616d 65582463 6c617373 6573554e 5355524c a2454758 4e534f62 6a656374 23404e00 00000000 00100009 13ffffff ffffffff ffd24344 4d4e5c4e 5355524c 52657175 657374a2 4f475c4e 5355524c 52657175 6573745f 100f4e53 4b657965 64417263 68697665 72d15253 5f101b4e 534b6579 65644172 63686976 65526f6f 744f626a 6563744b 65798001 00080011 001a0023 002d0032 00370044 004a007f 00820095 00b600d9 00e00103 01260149 01660189 01ac01c9 01e001e3 02050227 0249026b 028d02af 02d102d4 02f60318 033a033c 03450346 0348034a 034c034e 03500352 03540356 0358035a 035c035e 03600362 03640366 0368036a 036c036e 03700371 03780380 038c038e 03900392 03e103e6 03f103fa 04000403 040c0415 04170418 04210426 04330436 04430455 04580476 00000000 00000201 00000000 00000054 00000000 00000000 00000000 00000478>;
    
    NSURLSessionResumeServerDownloadDate = "Fri, 24 Mar 2017 02:43:46 GMT";
}
```

通过下载的代理方法监听下载的情况，需要实现下面的三个代理

```
<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>
```
NSURLSessionDownloadDelegate代理需要实现的方法：

```
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	//该方法获取下载进度
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    //下载成功，location为文件下载位置，为.tmp文件，此处需要对文件进行move操作，并把文件类型改为原本的类型。
}
```

NSURLSessionTaskDelegate代理需要实现的方法：

```
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //下载完成，出错或者成功都会调用，后面应用下载过程 进程被杀死会用到该方法
}
```

NSURLSessionDelegate代理需要实现的方法：

```
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
     //后台下载过程，下载完成调用该代理方法
}
```


### 2.断点续传

获取了resumeData，就可以通过下面的方法实现断点续传了。

```
self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
[self.downloadTask resume];
```

### 3.后台下载

在定义Session的时候，config指定了可以后台下载.在切到后台之后，Session的Delegate不会再收到消息，直到所有下载任务全都完成后，系统会调用ApplicationDelegate的如下代理：

```
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
	// 保存这个block 在Session的代理方法调用
    self.backgroundSessionCompletionHandler = completionHandler;
    //添加本地推送
}

```
之后，调用Session的代理方法`URLSession:downloadTask:didFinishDownloadingToURL:`和`URLSession:task:didCompleteWithError `，最后调用如下代理方法：

```
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
}
```

在这个代理方法中，需要调用之前`ApplicationDelegate`的代理方法保存的block。（看了好多资料都需要调用，但是ApplicationDelegate的代理方法不实现好像也没什么影响）

### 4.后台下载进程被杀死

进程被杀死以后，系统保存了error信息，在进入应用的时候,`NSURLSessionConfiguration`设置的`Identifier`就起作用了，当`Identifier`相同的时候，一旦生成Session对象并设置Delegate，马上可以收到上一次关闭程序之前没有汇报工作的Task的结束情况.

```
NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"bl_backgroundSessionConfiguration"];
_session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
```

在NSURLSessionTaskDelegate的代理方法可以通过error拿到resumeData，代码如下：

```
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]){
            self.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        }
    }
}
```

### iOS10的问题

在iOS10设备上出现如下错误：

```
2017-03-31 18:07:42.829 DownloadFileDemo[56517:736908] *** -[NSKeyedUnarchiver initForReadingWithData:]: data is NULL
2017-03-31 18:07:42.829 DownloadFileDemo[56517:736908] *** -[NSKeyedUnarchiver initForReadingWithData:]: data is NULL
2017-03-31 18:07:42.830 DownloadFileDemo[56517:736908] Invalid resume data for background download. Background downloads must use http or https and must download to an accessible file.
```

参考[Resume NSUrlSession on iOS10](http://stackoverflow.com/questions/39346231/resume-nsurlsession-on-ios10)，说这是一个bug，好像在iOS10.2解决，我测试的环境是10.1。报错的大概意思是对resumeData解档获取`NSURLSessionResumeCurrentRequest`和`NSURLSessionResumeOriginalRequest`失败，参考解决方案可以获得一个新的resumeData。

### Demo地址

* [Demo](https://github.com/xl51009429/DownLoadFileDemo)


### 参考资料：

* [NSURLSession简介](http://www.cnblogs.com/biosli/p/iOS_Network_URL_Session.html)
* [基于iOS 10、realm封装的下载器](http://www.jianshu.com/p/b4edfa0b71d8)
* [iOS 7 SDK: Background Transfer Service](https://code.tutsplus.com/tutorials/ios-7-sdk-background-transfer-service--mobile-20595)
* [Resume NSUrlSession on iOS10](http://stackoverflow.com/questions/39346231/resume-nsurlsession-on-ios10)
