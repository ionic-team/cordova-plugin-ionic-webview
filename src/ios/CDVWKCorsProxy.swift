//
//  CDVWKCorsProxy.swift
//  
//
//  Created by Raman Rasliuk on 27.11.18.
//

import Foundation

@objc class CDVWKCorsProxy : NSObject, XMLParserDelegate {

    var webserver: GCDWebServer

    private var skipHeaders = ["content-encoding", "content-security-policy", "set-cookie"]

    init(webserver: GCDWebServer) {
        self.webserver = webserver

        super.init()

        self.getConfig();


    }

    func setHandlers(urlPrefix: String?, serverUrl: String?, sslCheck: String?, useCertificates: [String]?, clearCookies: String?) {

        if (urlPrefix == nil || serverUrl == nil) {
            print("WK PROXY: ERROR SETTING PROXY. missing path or proxyUrl")

            return
        }

        let pattern = "^" + NSRegularExpression.escapedPattern(for: urlPrefix!) + ".*"

        let sslCheck = sslCheck ?? "default"

        print("WK PROXY: Setting proxy path", urlPrefix!, "to address", serverUrl!, "with ssl check mode", sslCheck)

        var sslTrust: URLSessionDelegate?

        if (sslCheck == "nocheck") {
            sslTrust = SSLTrustAny()
        } else if (sslCheck == "pinned") {
            sslTrust = SSLPinned(useCertificates)
        }


        if (clearCookies == "yes") {

            let cookieStore = HTTPCookieStorage.shared

            print("WK PROXY: Clearing cookies")

            for cookie in cookieStore.cookies ?? [] {
                cookieStore.deleteCookie(cookie)
            }

        }


        for method in ["GET", "POST", "PUT", "PATCH", "DELETE"] {
            webserver.addHandler(forMethod: method, pathRegex: pattern, request: GCDWebServerDataRequest.self, processBlock: { req in
                return self.sendProxyResult(urlPrefix!, serverUrl!, req, sslTrust)
            })
        }

    }

    private func sendProxyResult(_ prefix: String, _ serverUrl: String, _ req: GCDWebServerRequest, _ sslTrust: URLSessionDelegate?) -> GCDWebServerResponse? {

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
        var session: URLSession!

        if (sslTrust == nil) {
            session = URLSession.shared
        } else {
            let configuration = URLSessionConfiguration.default
            session = URLSession(configuration: configuration, delegate: sslTrust, delegateQueue: OperationQueue.main)
        }


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
            let sslCheck = attributeDict["sslCheck"]
            let useCertificates = attributeDict["useCertificates"]
            let clearCookies = attributeDict["clearCookies"]

            if (path != nil && proxyUrl != nil) {
                self.setHandlers(urlPrefix: path!, serverUrl: proxyUrl!, sslCheck: sslCheck, useCertificates: useCertificates?.components(separatedBy: ","), clearCookies: clearCookies)
            }

        }
    }

}


class SSLTrustAny : NSObject, URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))

            return
        }

        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }

}

class SSLPinned : NSObject, URLSessionDelegate {

    private var certificates: [Data] = []

    init(_ useCertificates: [String]?) {
        super.init()

        let certsPath = URL(fileURLWithPath: Bundle.main.bundlePath + "/www/certificates", isDirectory: true)

        let fileManager = FileManager.default

        if let enumerator = fileManager.enumerator(atPath: certsPath.path) {
            for file in enumerator {

                let certFileName = file as! String

                let fileUrl = URL(fileURLWithPath: certFileName, relativeTo: certsPath)

                if (fileUrl.path.hasSuffix(".der") && (useCertificates == nil || useCertificates!.contains(certFileName))) {
                    do {
                        let certData = try Data(contentsOf: fileUrl)
                        self.certificates.append(certData)
                    } catch {
                        print("WK PROXY: ERROR to load certificate", fileUrl.path)
                    }
                }

            }
        }

    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {

        // Adapted from OWASP https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning#iOS

        if (certificates.count > 0 && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                var secresult = SecTrustResultType.invalid
                let status = SecTrustEvaluate(serverTrust, &secresult)

                if(errSecSuccess == status) {
                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                        let serverCertificateData = SecCertificateCopyData(serverCertificate)
                        let data = CFDataGetBytePtr(serverCertificateData);
                        let size = CFDataGetLength(serverCertificateData);
                        let certServer = Data(bytes: data!, count: size)

                        for certData in self.certificates {

                            if (certServer == certData) {
                                completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))

                                return
                            }
                        }

                    }
                }
            }
        }

        // Pinning failed
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }

}
