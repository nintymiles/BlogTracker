//
//  ViewController.swift
//  BlogTracker
//
//  Created by SeanRen on 11/17/16.
//  Copyright © 2016 SeanRen. All rights reserved.
//

import Cocoa
import WebKit
import Kanna

extension NSDate
{
    convenience
    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        let d = dateStringFormatter.date(from: dateString)!
        self.init(timeInterval:0, since:d)
    }

    class func today() -> String {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        return dateStringFormatter.string(from: NSDate() as Date)
    }
}

class ViewController: NSViewController,WebFrameLoadDelegate {
    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var webView: WebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.loadRequest()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func loadRequest() {
        let url = URL(string:"http://blog.sohu.com/s/NTk1MzIwOTU/entry/")

        let httpRequest = URLRequest(url: url!)

        //注意URLRequest不是webView直接load
        self.webView.mainFrame.load(httpRequest)
    }


    // MARK: - WebResourceLoadDelegate
    func webView(_ sender: WebView!, didStartProvisionalLoadFor frame: WebFrame!) {
        infoLabel.stringValue = "Webview Start Loading"
    }

    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        infoLabel.stringValue = "Webview End Loading"

        Thread.sleep(forTimeInterval: 3)

        //意图为获取加载JS后的Html，故而没有直接请求http
        let htmlString = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML")
        //        print(htmlString!)

        var articles:String?
        infoLabel.stringValue = "Begin Processing HTML Page"
        if let doc = HTML(html: htmlString!, encoding: .utf8) {
            print(doc.title ?? "")

            // Search for nodes by CSS
            for divBlock in doc.css("div.newBlog-list-title") {
                guard let dateStr = divBlock.at_css(".date")?.innerHTML else {continue}
                let todayStr = NSDate.today()

                //只取当天的文章
                if dateStr == todayStr {
                    guard let link = divBlock.at_xpath("a") else {
                        break
                    }
                    guard let linkHref = link["href"] else {
                        break
                    }
                    self.loadPageHtml(url: URL(string:linkHref)!,fileName:link.text!)

                    print(link.text ?? "articles updating today，but error occured")
                    articles = articles?.appending(link.text!+"\n")
                } else {
                    print("No Articles Today!!!!!!!!!!!!!!!")
                }

            }

        }
        infoLabel.stringValue = "Updating articles:\n\( articles ?? "No")"
    }

    func loadPageHtml(url:URL,fileName:String) {
        let htmlString = try! String.init(contentsOf: url)

        let filename = getDocumentsDirectory().appendingPathComponent("test/\(fileName).html")

        do {
            try htmlString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            fatalError("failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding")
        }

    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

}

