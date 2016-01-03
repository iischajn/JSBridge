package org.chajn.jsbridge;

import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.HashMap;
import java.util.Map;

public class JSBridge {

    static Map<String, JSBridgeHandler> handlerList = new HashMap<String, JSBridgeHandler>();


    static void initWithPageName(String pageName, final String jsStr, WebView webView){

        webView.getSettings().setJavaScriptEnabled(true);
        webView.setBackgroundColor(0); // 设置背景色
        webView.loadUrl("file:///android_asset/" + pageName + ".html");
        webView.setWebViewClient(
            new WebViewClient() {
                public boolean shouldOverrideUrlLoading(WebView view, String url) {
                    try {
                        url = URLDecoder.decode(url, "UTF-8");
                    } catch (UnsupportedEncodingException e) {
                        e.printStackTrace();
                    }
                    if (url.startsWith("jsbridge://postMessage/")) {
                        String jsonData = url.replace("jsbridge://postMessage/", "");
                        JSONObject json = new JSONObject();;

                        try {
                            json = new JSONObject(jsonData);
                        } catch (JSONException e) {
                        }
                        String handlerName = json.optString("handlerName");
                        JSONObject data = json.optJSONObject("data");
                        JSBridgeHandler jh = handlerList.get(handlerName);
                        if(jh != null){
                            jh.handler(data);
                        }
                        return true;
                    }  else {
                        return super.shouldOverrideUrlLoading(view, url);
                    }
                }
                public void onPageFinished(WebView view, String url) {
                    view.loadUrl("javascript:(function(){window.WebViewJavascriptBridge={callbackIdList:{},callHandler:function(a,d,e){var b={handlerName:a,data:d};if(e){var c='bridage'+Math.ceil(Math.random()*1000000000);this.callbackIdList[c]=e;b.callbackId=c}var e=JSON.stringify(b);window.location.href='jsbridge://postMessage/'+e},registerHandler:function(a,b){this.callbackIdList[a]=b},execCallback:function(a){if(a&&a.callbackId){this.callbackIdList[a.callbackId]&&this.callbackIdList[a.callbackId](a.data);if(a.callbackId.indexOf('bridage')!=-1){delete this.callbackIdList[a.callbackId]}}}};var ev = document.createEvent('HTMLEvents');ev.initEvent('WebViewJavascriptBridgeReady', true, true);document.dispatchEvent(ev);})(); ");
                    JSBridge.execJS(view, "nativeReady", jsStr, false);
                }
            }
        );
    }

    static void registerHandler(String handlerName, JSBridgeHandler handler) {
        if (handler != null) {
            handlerList.put(handlerName, handler);
        }
    }

    static void execJS(WebView view, String funcName, String jsData, boolean isBridage) {
        String namespace =  isBridage ? "window.WebViewJavascriptBridge": "window";
        view.loadUrl("javascript:"+namespace+"['"+funcName+"'](" + jsData + ")");
    }

    static void execBridge(WebView view, String callbackId, String jsonData) {
        if (jsonData == null) {
            jsonData = "{callbackId:'"+callbackId+"'}";
        }else{
            jsonData = "{callbackId:'"+callbackId+"', data: "+jsonData+"}";
        }
        JSBridge.execJS(view, "execCallback", jsonData, true);
    }

    static void callHandler(WebView view, String funcName, String jsonData) {
        JSBridge.execBridge(view, funcName, jsonData);
    }
}

class JSBridgeHandler {

    void handler(JSONObject data){

    }

}

//, JSBridgeCallBack callback
//class JSBridgeCallBack {
//
//    public void onCallBack(String data){
//
//    }
//
//}

