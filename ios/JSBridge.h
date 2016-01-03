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

@interface JSBridge : NSObject <WKScriptMessageHandler>;

@property (strong) WKWebView *webView;

@property (readwrite, nonatomic, strong) NSMutableDictionary *handlerList;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)loadPage:(NSString *) pageName viewBg:(NSString *)bg initJS:(NSString *)initJS;

//- (NSString *)pathForWKWebViewSandboxBugWithOriginalPath:(NSString *)filePath;

- (void)execJS:(NSString *)funcName jsStr:(NSString *)jsStr isBridage:(BOOL)isBridage;

- (void) registerHandler: (NSString*) handlerName handler: (JSBridgeHandler)handler;

- (void) callHandler: (NSString*) handlerName;

- (void) callHandler: (NSString*) handlerName jsonData: (NSString *) jsonData;

//- (void) callHandler: (NSString*) handlerName jsonData: (NSString *) jsonData responseCallback: (JSBridgeResponseCallback) responseCallback;


@end

