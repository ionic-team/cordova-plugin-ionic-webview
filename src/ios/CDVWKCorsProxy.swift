//
//  CDVWKCorsProxy.swift
//  
//
//  Created by Raman Rasliuk on 27.11.18.
//

import Foundation

@objc class CDVWKCorsProxy : NSObject, XMLParserDelegate {

    var webserver: GCDWebServer

    private var skipHeaders = ["content-encoding", "content-security-policy"]

    init(webserver: GCDWebServer) {
        self.webserver = webserver

        super.init()

        self.getConfig();

    }

    func setHandlers(urlPrefix: String, serverUrl: String) {

        let pattern = "^" + NSRegularExpression.escapedPattern(for: urlPrefix) + ".*"

        webserver.addHandler(forMethod: "GET", pathRegex: pattern, request: GCDWebServerDataRequest.self, processBlock: { req in
            return self.sendProxyResult(urlPrefix, serverUrl, req)
        })

        webserver.addHandler(forMethod: "POST", pathRegex: pattern, request: GCDWebServerDataRequest.self, processBlock:{ req in
            return self.sendProxyResult(urlPrefix, serverUrl, req)
        })

        webserver.addHandler(forMethod: "PUT", pathRegex: pattern, request: GCDWebServerDataRequest.self, processBlock:{ req in
            return self.sendProxyResult(urlPrefix, serverUrl, req)
        })

        webserver.addHandler(forMethod: "PATCH", pathRegex: pattern, request: GCDWebServerDataRequest.self, processBlock:{ req in
            return self.sendProxyResult(urlPrefix, serverUrl, req)
        })

        webserver.addHandler(forMethod: "DELETE", pathRegex: pattern, request: GCDWebServerDataRequest.self, processBlock:{ req in
            return self.sendProxyResult(urlPrefix, serverUrl, req)
        })

    }

    private func sendProxyResult(_ prefix: String, _ serverUrl: String, _ req: GCDWebServerRequest) -> GCDWebServerResponse? {

        let query = req.url.query == nil ? "" : "?" + req.url.query!
        let url = URL(string: serverUrl + req.path.substring(from: prefix.endIndex) + query)

        if (url == nil) {
            return self.sendError(error: "Invalid url")
        }

        let request = NSMutableURLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 320000)

        request.httpMethod = req.method
        request.allHTTPHeaderFields = req.headers as? [String: String]
        request.allHTTPHeaderFields?["Host"] = url!.host

        if (req.hasBody()) {
            request.httpBody = (req as! GCDWebServerDataRequest).data
        }

        var finalResponse: GCDWebServerDataResponse? = nil

        let session = URLSession.shared

        let task = session.dataTask(with: request as URLRequest) { data, urlResp, error in
            if (error != nil) {
                finalResponse = self.sendError(error: error?.localizedDescription) as? GCDWebServerDataResponse

                return
            }

            let httpResponse = urlResp as! HTTPURLResponse

            let resp = GCDWebServerDataResponse(data: data!, contentType: "application/x-unknown")

            resp.statusCode = httpResponse.statusCode

            for key in httpResponse.allHeaderFields {

                let headerKey: String! = self.toString(v: key.0 as AnyObject)
                let headerValue: String! = self.toString(v: key.1 as AnyObject)

                let headerKeyLower = headerKey.lowercased()

                if (headerKey == "" || self.skipHeaders.contains(headerKeyLower)) {
                    continue
                }

                resp.setValue(headerValue, forAdditionalHeader: headerKey)

            }

            resp.setValue(String(data!.count), forAdditionalHeader: "Content-Length")

            finalResponse = resp

        }

        task.resume()

        while (finalResponse == nil) {
            Thread.sleep(forTimeInterval: 0.001)
        }

        return finalResponse

    }

    private func getConfig() {
        if let path = Bundle.main.url(forResource: "config", withExtension: "xml") {
            if let parser = XMLParser(contentsOf: path) {
                parser.delegate = self
                parser.parse()
            }
        }
    }

    private func sendError(error: String?) -> GCDWebServerResponse! {
        let msg = error == nil ? "An error occured" : error!
        let errorData = msg.data(using: String.Encoding.utf8, allowLossyConversion: true)
        let resp = GCDWebServerDataResponse(data: errorData!, contentType: "text/plain")
        resp.statusCode = 500

        return resp
    }

    private func toString(v: AnyObject?) -> String! {
        if (v == nil) { return ""; }
        return String(stringInterpolationSegment: v!)
    }


    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "wkproxy" {

            let path = attributeDict["path"]
            let proxyUrl = attributeDict["proxyUrl"]

            if (path != nil && proxyUrl != nil) {

                print("Setting proxy path", path!, "to address", proxyUrl!)

                self.setHandlers(urlPrefix: path!, serverUrl: proxyUrl!)
            }

        }
    }

}


