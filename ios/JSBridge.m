//
//  ViewController.m
//  JSBridge
//
//  Created by 陈健 on 15/11/17.
//  Copyright © 2015年 陈健. All rights reserved.
//

#import "JSBridge.h"

@implementation JSBridge



- (instancetype)initWithFrame: (CGRect)frame
{
    
    if (self == [super init]) {
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        [config.userContentController addScriptMessageHandler:self name:@"WebViewJavascriptBridge"];
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
        [webView setBackgroundColor:[UIColor clearColor]];
        [webView setOpaque:NO];
        
        [self setWebView: webView];
        [self setHandlerList: [[NSMutableDictionary alloc]init]];
        [self checkCachePath];
    }
    
    return self;
}

- (void)loadPage:(NSString *)pageName viewBg:(NSString *) bg initJS:(NSString *)initJS {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    NSString *dirPath = [cachesDir stringByAppendingPathComponent:@"www"];
    
    NSString *fileName = [NSString stringWithFormat:@"/%@.html", pageName];
    NSString *filePath = [dirPath stringByAppendingPathComponent: fileName];

    [self.webView.configuration.userContentController removeAllUserScripts];
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:@"(function(){window.WebViewJavascriptBridge={callbackIdList:{},callHandler:function(a,d,e){var b={handlerName:a,data:d};if(e){var c='bridage'+Math.ceil(Math.random()*1000000000);this.callbackIdList[c]=e;b.callbackId=c}window.webkit.messageHandlers.WebViewJavascriptBridge.postMessage(b)},registerHandler:function(a,b){this.callbackIdList[a]=b},execCallback:function(a){if(a&&a.callbackId){this.callbackIdList[a.callbackId]&&this.callbackIdList[a.callbackId](a.data);if(a.callbackId.indexOf('bridage')!=-1){delete this.callbackIdList[a.callbackId]}}}};var ev = document.createEvent('HTMLEvents');ev.initEvent('WebViewJavascriptBridgeReady', true, true);document.dispatchEvent(ev);})(); " injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];

    [self.webView.configuration.userContentController addUserScript:script];
    
    if(initJS){
        WKUserScript *initScript = [[WKUserScript alloc] initWithSource:initJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [self.webView.configuration.userContentController addUserScript:initScript];
    }
    
    if(bg){
        [self.webView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed: [dirPath stringByAppendingPathComponent:bg]]]];
    }else{
//        [self.webView setBackgroundColor: UIColorFromRGB(0xf8f8f8)];
    }
    
    NSURL* filePathUrl = [NSURL fileURLWithPath:filePath];
    SEL sel = NSSelectorFromString(@"loadFileURL:allowingReadAccessToURL:");
    if ([self.webView respondsToSelector:sel]) {
        [self.webView loadFileURL:filePathUrl allowingReadAccessToURL:[NSURL fileURLWithPath:dirPath]];
    } else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:filePathUrl]];
    }
}

- (BOOL)checkCachePath {

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [infoDict objectForKey:@"CFBundleVersion"];
    NSString *version = [[NSUserDefaults standardUserDefaults] objectForKey:@"h5wwwVersion"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    NSString *tempPath = [cachesDir stringByAppendingPathComponent:@"www"];
    NSError *error = nil;
    
    // 正式环境中最好把这段注释打开 除非没找到临时目录或版本号不一致 其他情况不再拷贝文件到临时目录
//    if([manager fileExistsAtPath:tempPath] && [version isEqualToString:currentVersion]){
//        return YES;
//    }else{
//        if (![manager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:&error]) {
//            NSLog(@"Could not create www directory. Error: %@", error);
//            return NO;
//        }
//    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:@"h5wwwVersion"];
    
    NSString *dirPath = [[NSBundle mainBundle] pathForResource:@"www" ofType:@"bundle"];
    NSArray* array = [manager contentsOfDirectoryAtPath: dirPath error:&error];

    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSError *error = nil;
        NSString *itemPath = [dirPath stringByAppendingPathComponent:obj];
        NSString *tempItemPath = [tempPath stringByAppendingPathComponent:obj];
        if([manager fileExistsAtPath:tempItemPath]){
            [manager removeItemAtPath:tempItemPath error:&error];
        }
        [manager copyItemAtPath:itemPath toPath:tempItemPath error:&error];
    }];
    
    return YES;
}

- (void)execJS:(NSString *)funcName jsStr:(NSString *)jsStr isBridage:(BOOL)isBridage {
    
    NSString *namespace = isBridage ? @"window.WebViewJavascriptBridge":@"window";
    
    NSString *js = [NSString stringWithFormat:@"(function(){%@['%@'](%@);})();", namespace, funcName, jsStr];
    NSLog(@"%@", js);
    [self.webView evaluateJavaScript:js completionHandler:^(id val,NSError *error){
        NSLog(@"Completion: %@ : %@", val, error);
    }];
    
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSString *handlerName = message.body[@"handlerName"];
    NSString *data = message.body[@"data"];
    NSString *callbackId = message.body[@"callbackId"];
    
    JSBridgeResponseCallback responseCallback = NULL;
    
    if (callbackId) {
        responseCallback = ^(NSString *jsonData) {
            if (jsonData == nil) {
                jsonData = [NSString stringWithFormat:@"{callbackId:'%@'}", callbackId];
            }else{
                jsonData = [NSString stringWithFormat:@"{callbackId:'%@', data: %@}", callbackId, jsonData];
            }
            [self execJS:@"execCallback" jsStr:jsonData isBridage: YES];
        };
    } else {
        responseCallback = ^(NSString *jsonData) {};
    }
    
    if (!handlerName) {
        NSLog(@"JSBridge: ERROR: need handlerName");
        return responseCallback(@"{errno:-1,msg:'need handlerName'}");
    }
    
    JSBridgeHandler handler = [self.handlerList objectForKey:handlerName];
    
    if (!handler) {
        NSLog(@"JSBridge: ERROR: not Object-C handler %@", handlerName);
        return responseCallback(@"{errno:-2, msg:'not Object-C handler'}");
    }
    
    @try {
        handler(data, responseCallback);
    }
    @catch (NSException *exception) {
        NSLog(@"JSBridge: WARNING: objc handler threw. %@ %@", message, exception);
        NSString *msg = [NSString stringWithFormat:@"{errno:-3, msg:'%@'}", message];
        
        return responseCallback(msg);
    }
    
}

- (void)execBridge:(NSString*)callbackId jsonData:(NSString*)jsonData {
    //responseCallback:(JSBridgeResponseCallback)responseCallback
    if (jsonData == nil) {
        jsonData = [NSString stringWithFormat:@"{callbackId:'%@'}", callbackId];
    }else{
        jsonData = [NSString stringWithFormat:@"{callbackId:'%@', data: %@}", callbackId, jsonData];
    }
    
    [self execJS:@"execCallback" jsStr:jsonData isBridage: YES];
}


-(void)registerHandler: (NSString *)handlerName handler:(JSBridgeHandler) handler {
    [self.handlerList setObject:handler forKey:handlerName];
}

- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName jsonData:nil];// responseCallback:nil
}

- (void)callHandler:(NSString *)handlerName jsonData:(NSString *)jsonData {
    [self execBridge:handlerName jsonData:jsonData];
//    [self callHandler:handlerName jsonData:jsonData responseCallback:nil];
}

//- (void)callHandler:(NSString *)handlerName jsonData:(NSString *)jsonData responseCallback:(JSBridgeResponseCallback)responseCallback {
//    [self execBridge:handlerName jsonData:jsonData responseCallback:responseCallback];
//}

@end
