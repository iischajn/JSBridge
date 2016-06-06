//
//  ViewController.m
//  JSBridge
//
//  Created by 陈健 on 15/11/17.
//  Copyright © 2015年 陈健. All rights reserved.
//

#import "JSBridge.h"
//#import "MBProgressHUD.h"
@implementation JSBridge

@synthesize webView;
-(void)setWebView:(UIView *)webView
{
    webView = (UIView *) webView;
}

-(UIView *)webView
{
    if(IOS8){
        return _wkwebview;
    }else{
        return _uiwebview;
    }
}

- (instancetype)initWithFrame: (CGRect)frame
{

    if(!IOS8){
        UIWebView *uiwebview = [[UIWebView alloc] initWithFrame:frame];
        self.uiwebview = uiwebview;
        [self setWebView: uiwebview];
        return self;
    }
    
    if (self == [super init]) {
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        [config.userContentController addScriptMessageHandler:self name:@"WebViewJavascriptBridge"];
        
        WKWebView *wkwv = [[WKWebView alloc] initWithFrame:frame configuration:config];
        self.wkwebview = wkwv;

        [wkwv setBackgroundColor:[UIColor clearColor]];
        [wkwv setOpaque:NO];
        
        wkwv.navigationDelegate = self;
        wkwv.scrollView.delegate = self;
        wkwv.scrollView.bounces = NO;
        [wkwv.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        
        [self setWebView: wkwv];
        [self setHandlerList: [[NSMutableDictionary alloc]init]];
        [self checkCachePath];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    DLog(@"chage = %@",change);
}

- (void)loadUrl:(NSString *)url initJS:(NSString *)initJS {
    if(!IOS8){
        [self loadPage:@"" initJS:nil];
        return;
    }
    
    if(![AFNetworkReachabilityManager sharedManager].reachable){
        [self loadPage:@"offline" initJS:[NSString stringWithFormat:@"nativeReady({reload:1,url:'%@',local:0})",url]];
        return;
    }
    
    [self.wkwebview.configuration.userContentController removeAllUserScripts];
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:@"(function(){window.WebViewJavascriptBridge={callbackIdList:{},callHandler:function(a,d,e){var b={handlerName:a,data:d};if(e){var c='bridage'+Math.ceil(Math.random()*1000000000);this.callbackIdList[c]=e;b.callbackId=c}window.webkit.messageHandlers.WebViewJavascriptBridge.postMessage(b)},registerHandler:function(a,b){this.callbackIdList[a]=b},execCallback:function(a){if(a&&a.callbackId){this.callbackIdList[a.callbackId]&&this.callbackIdList[a.callbackId](a.data);if(a.callbackId.indexOf('bridage')!=-1){delete this.callbackIdList[a.callbackId]}}}};var ev = document.createEvent('HTMLEvents');ev.initEvent('WebViewJavascriptBridgeReady', true, true);document.dispatchEvent(ev);})(); " injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    [self.wkwebview.configuration.userContentController addUserScript:script];
    
    if(initJS){
        WKUserScript *initScript = [[WKUserScript alloc] initWithSource:initJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [self.wkwebview.configuration.userContentController addUserScript:initScript];
    }
    
    [self.wkwebview setBackgroundColor: UIColorFromRGB(0xf8f8f8)];
    
    [self.wkwebview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    
    [self showLoadingInView];
    
    [self registerCommonComp];
}

- (void)loadPage:(NSString *)pageName initData:(NSDictionary *)dicData {
    NSMutableDictionary *mutData = [NSMutableDictionary dictionaryWithDictionary:dicData];
    
    mutData[@"chn"] = @"appstore";
    mutData[@"pageName"] = pageName;
    
    int online = [AFNetworkReachabilityManager sharedManager].reachable;
    
    NSData *JSONData= [NSJSONSerialization dataWithJSONObject:mutData options:NSJSONWritingPrettyPrinted error:NULL];
    
    NSString *js = [NSString stringWithFormat:@"nativeReady(%@)",[[NSString alloc]initWithData:JSONData encoding:NSUTF8StringEncoding]];
    NSString *local =  mutData[@"local"];
    if(!online && !local){
        [self loadPage:@"offline" initJS:js];
        return;
    }
    
    [self loadPage:pageName initJS:js];
}


- (void)loadPage:(NSString *)pageName initJS:(NSString *)initJS {
    
    if(!IOS8){
        NSString *dirPath = [[NSBundle mainBundle] pathForResource:@"www" ofType:@"bundle"];
        NSString *itemPath = [dirPath stringByAppendingPathComponent:@"empty.html"];
        
        NSURL* url = [NSURL fileURLWithPath: itemPath];//创建URL
        NSURLRequest* request = [NSURLRequest requestWithURL:url];//创建NSURLRequest
        [self.uiwebview loadRequest:request];
        return;
    }
    
    NSString *dirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"www"];
    
    NSString *fileName = [NSString stringWithFormat:@"/%@.html", pageName];
    NSString *filePath = [dirPath stringByAppendingPathComponent: fileName];
    
    
    [self.wkwebview.configuration.userContentController removeAllUserScripts];
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:@"(function(){window.WebViewJavascriptBridge={callbackIdList:{},callHandler:function(a,d,e){var b={handlerName:a,data:d};if(e){var c='bridage'+Math.ceil(Math.random()*1000000000);this.callbackIdList[c]=e;b.callbackId=c}window.webkit.messageHandlers.WebViewJavascriptBridge.postMessage(b)},registerHandler:function(a,b){this.callbackIdList[a]=b},execCallback:function(a){if(a&&a.callbackId){this.callbackIdList[a.callbackId]&&this.callbackIdList[a.callbackId](a.data);if(a.callbackId.indexOf('bridage')!=-1){delete this.callbackIdList[a.callbackId]}}}};var ev = document.createEvent('HTMLEvents');ev.initEvent('WebViewJavascriptBridgeReady', true, true);document.dispatchEvent(ev);})(); " injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    [self.wkwebview.configuration.userContentController addUserScript:script];
    
    if(initJS){
        WKUserScript *initScript = [[WKUserScript alloc] initWithSource:initJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [self.wkwebview.configuration.userContentController addUserScript:initScript];
    }

    [self.wkwebview setBackgroundColor: UIColorFromRGB(0xf8f8f8)];

    self.isContentReady = NO;

    NSURL* filePathUrl = [NSURL fileURLWithPath:filePath];
    SEL sel = NSSelectorFromString(@"loadFileURL:allowingReadAccessToURL:");
    if ([self.wkwebview respondsToSelector:sel]) {
        [self.wkwebview loadFileURL:filePathUrl allowingReadAccessToURL:[NSURL fileURLWithPath:dirPath]];
    } else {
        [self.wkwebview loadRequest:[NSURLRequest requestWithURL:filePathUrl]];
    }
    if(![pageName  isEqual: @"weight_record"] &&
       ![pageName  isEqual: @"bfr_record"]){
        [self showLoadingInView];
    }
    
    [self registerCommonComp];
    
}

- (BOOL)checkCachePath {
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [infoDict objectForKey:@"CFBundleVersion"];
    NSString *version = [[NSUserDefaults standardUserDefaults] objectForKey:@"h5wwwVersion"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"www"];
    NSError *error = nil;
    

#ifdef DEBUG
    //测试环境每次覆盖
    if (![manager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Could not create www directory. Error: %@", error);
        return NO;
    }
#else
    if(![manager fileExistsAtPath:tempPath]){
        if (![manager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Could not create www directory. Error: %@", error);
            return NO;
        }
    }else if([version isEqualToString:currentVersion]){
        return YES;
    }
#endif
    
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
    if(!IOS8){
        return;
    }

    NSString *namespace = isBridage ? @"window.WebViewJavascriptBridge":@"window";
    
    NSString *js = [NSString stringWithFormat:@"(function(){%@['%@'](%@);})();", namespace, funcName, jsStr];
    NSLog(@"%@", js);
    [self.wkwebview evaluateJavaScript:js completionHandler:^(id val,NSError *error){
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
        return responseCallback(@"{errno:-1,msg:'need handlerName'}");
    }
    
    JSBridgeHandler handler = [self.handlerList objectForKey:handlerName];
    
    if (!handler) {
        return responseCallback(@"{errno:-2, msg:'not Object-C handler'}");
    }
    
    @try {
        handler(data, responseCallback);
    }
    @catch (NSException *exception) {
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

-(void) registerCommonComp {
    
    [self registerHandler:@"contentReady" handler:^(id data, JSBridgeResponseCallback response) {
        self.isContentReady = YES;
    }];
}


-(void) registerWebComp:(UIViewController *) weakView{

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

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self hideLoadingInView];
}

/*!
 *  显示正在加载框
 */
- (void)showLoadingInView
{
    if (!IOS8) {
        return;
    }
    
    if(self.hud) return;
//    self.hud = [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
//    self.hud.labelText = @"正在加载";
}

/*!
 *  隐藏正在加载框
 */
- (void)hideLoadingInView
{
    if (self.hud) {
        
//        [self.hud hide:YES];
        self.hud = nil;
    }
    
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.bridgeScrollBlock) {
        self.bridgeScrollBlock(scrollView);
    }
}

@end
