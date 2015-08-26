//
//  ViewController.swift
//  Coda
//
//  Created by Joyce Echessa on 1/8/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import WebKit
let MessageHandler = "didGetPosts"
let PostSelected = "postSelected"

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView
    var postsWebView: WKWebView?
    var posts: [Post] = []
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var recentPostsButton: UIBarButtonItem!
    
    required init(coder aDecoder: NSCoder) {
        let config = WKWebViewConfiguration()
        let scriptURL = NSBundle.mainBundle().pathForResource("hideSections", ofType: "js")
        let scriptContent = String(contentsOfFile:scriptURL!, encoding:NSUTF8StringEncoding, error: nil)
        let script = WKUserScript(source: scriptContent!, injectionTime: .AtDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        self.webView = WKWebView(frame: CGRectZero, configuration: config)
        super.init(coder: aDecoder)
        self.webView.navigationDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.insertSubview(webView, belowSubview: progressView)
        
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        let height = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: -44)
        let width = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "title", options: .New, context: nil)
        
        webView.loadRequest(NSURLRequest(URL:NSURL(string:"http://www.appcoda.com")!))
        
        backButton.enabled = false
        forwardButton.enabled = false
        recentPostsButton.enabled = false
        
        let config = WKWebViewConfiguration()
        let scriptURL = NSBundle.mainBundle().pathForResource("getPosts", ofType: "js")
        let scriptContent = String(contentsOfFile:scriptURL!, encoding:NSUTF8StringEncoding, error: nil)
        let script = WKUserScript(source: scriptContent!, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        config.userContentController.addScriptMessageHandler(self, name: MessageHandler)
        postsWebView = WKWebView(frame: CGRectZero, configuration: config)
        postsWebView!.loadRequest(NSURLRequest(URL:NSURL(string:"http://www.appcoda.com")!))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "postSelected:", name: PostSelected, object: nil)
    }
    
    @IBAction func back(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func reload(sender: UIBarButtonItem) {
        let request = NSURLRequest(URL:webView.URL!)
        webView.loadRequest(request)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<()>) {
        if (keyPath == "loading") {
            backButton.enabled = webView.canGoBack
            forwardButton.enabled = webView.canGoForward
        }
        if (keyPath == "estimatedProgress") {
            progressView.hidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
        if (keyPath == "title") {
            title = webView.title
        }
    }
    
    func webView(webView: WKWebView!, didFinishNavigation navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
    }
    
    func webView(webView: WKWebView!, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError!) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func webView(webView: WKWebView!, decidePolicyForNavigationAction navigationAction: WKNavigationAction!, decisionHandler: ((WKNavigationActionPolicy) -> Void)!) {
        if (navigationAction.navigationType == WKNavigationType.LinkActivated && !navigationAction.request.URL.host!.lowercaseString.hasPrefix("www.appcoda.com")) {
            UIApplication.sharedApplication().openURL(navigationAction.request.URL)
            decisionHandler(WKNavigationActionPolicy.Cancel)
        } else {
            decisionHandler(WKNavigationActionPolicy.Allow)
        }
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if (message.name == MessageHandler) {
            if let postsList = message.body as? [Dictionary<String, String>] {
                for ps in postsList {
                    let post = Post(dictionary: ps)
                    posts.append(post)
                }
                recentPostsButton.enabled = true
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "recentPosts") {
            let navigationController = segue.destinationViewController as UINavigationController
            let postsViewController = navigationController.topViewController as PostsTableViewController
            postsViewController.posts = posts
        }
    }
    
    func postSelected(notification:NSNotification) {
        webView.loadRequest(NSURLRequest())
        let post = notification.object as Post
        webView.loadRequest(NSURLRequest(URL:NSURL(string:post.postURL)!))
    }

}

