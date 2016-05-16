//
//  ViewController.h
//  JSBridge
//
//  Created by 陈健 on 15/11/17.
//  Copyright © 2015年 陈健. All rights reserved.
//

#import <UIKit/UIKit.h>

@import WebKit;

typedef void (^JSBridgeResponseCallback)(NSString *response);
typedef void (^JSBridgeHandler)(id data, JSBridgeResponseCallback response);
typedef void(^BridgeScrollBlock)(UIScrollView *scrollView);

@interface JSBridge : NSObject <WKScriptMessageHandler,WKNavigationDelegate,UIScrollViewDelegate>;

@property (strong) WKWebView *wkwebview;

@property (strong) UIWebView *uiwebview;

@property UIView *webView;

@property(nonatomic) BOOL isContentReady;

@property (strong) MBProgressHUD *hud;

@property (nonatomic,copy) BridgeScrollBlock bridgeScrollBlock;

@property (readwrite, nonatomic, strong) NSMutableDictionary *handlerList;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)loadUrl:(NSString *)url initJS:(NSString *)initJS;

- (void)loadPage:(NSString *)pageName initData:(NSDictionary *)dicData;

- (void)loadPage:(NSString *) pageName initJS:(NSString *)initJS;

- (void)execJS:(NSString *)funcName jsStr:(NSString *)jsStr isBridage:(BOOL)isBridage;

-(void) registerWebComp:(UIViewController *) weakView;

- (void) registerHandler: (NSString*) handlerName handler: (JSBridgeHandler)handler;

- (void) callHandler: (NSString*) handlerName;

- (void) callHandler: (NSString*) handlerName jsonData: (NSString *) jsonData;

//- (void) callHandler: (NSString*) handlerName jsonData: (NSString *) jsonData responseCallback: (JSBridgeResponseCallback) responseCallback;

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;

@end

