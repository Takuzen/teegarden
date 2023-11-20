////
////  PaApi.swift
////  booksp
////
////  Created by NANAMI MIMURA on 2023/11/12.
////
//
//import Foundation
//import CommonCrypto
//
//struct SearchItemsRequest: Codable {
//    let partnerTag: String
//    let partnerType: String
//    let keywords: String
//    let searchIndex: String
//    let itemCount: Int
//    let resources: [String]
//}
//
//struct ItemInfo: Codable {
//    let title: String
//    let detailPageURL: String
//    let ASIN: String
//}
//
//struct SearchResult: Codable {
//    let items: [ItemInfo]
//}
//
//struct Response: Codable {
//    let searchResult: SearchResult?
//}
//
//func searchItems() {
//    let accessKey = "<YOUR ACCESS KEY>"
//    let secretKey = "<YOUR SECRET KEY>"
//    let partnerTag = "<YOUR PARTNER TAG>"
//    let host = "webservices.amazon.com"
//    let region = "us-east-1"
//    
//    let searchItemsRequest = SearchItemsRequest(
//        partnerTag: partnerTag,
//        partnerType: "ASSOCIATES",
//        keywords: "Harry Potter",
//        searchIndex: "All",
//        itemCount: 1,
//        resources: ["ITEMINFO_TITLE", "OFFERS_LISTINGS_PRICE"]
//    )
//    
//    guard let url = URL(string: "https://\(host)/paapi5/searchitems") else { return }
//    
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//    request.addValue(accessKey, forHTTPHeaderField: "X-Access-Key")
//    request.addValue(secretKey, forHTTPHeaderField: "X-Secret-Key")
//    
//    do {
//        let requestData = try JSONEncoder().encode(searchItemsRequest)
//        request.httpBody = requestData
//    } catch {
//        print("Error encoding request data: \(error)")
//        return
//    }
//    
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//        guard let data = data, error == nil else {
//            print("Error making request: \(String(describing: error))")
//            return
//        }
//        
//        do {
//            let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
//            if let searchResult = decodedResponse.searchResult {
//                for item in searchResult.items {
//                    print("Title: \(item.title)")
//                    print("DetailPageURL: \(item.detailPageURL)")
//                    print("ASIN: \(item.ASIN)")
//                }
//            }
//        } catch {
//            print("Error decoding response: \(error)")
//        }
//    }
//    
//    task.resume()
//}
//
//
//class AWSV4Auth {
//    private let accessKey: String
//    private let secretKey: String
//    private let host: String
//    private let region: String
//    private let service: String
//    private let methodName: String
//    private var headers: [String: String]
//    private let payload: String
//    private let path: String
//    private let timestamp: Date
//
//    private var xAmzDateTime: String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        return dateFormatter.string(from: timestamp)
//    }
//
//    private var xAmzDate: String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyyMMdd"
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        return dateFormatter.string(from: timestamp)
//    }
//
//    private var signedHeader: String {
//        return headers.keys.map { $0.lowercased() }.sorted().joined(separator: ";")
//    }
//
//    private var credentialScope: String {
//        return "\(xAmzDate)/\(region)/\(service)/aws4_request"
//    }
//
//    private var algorithm: String {
//        return "AWS4-HMAC-SHA256"
//    }
//
//    init(accessKey: String, secretKey: String, host: String, region: String, service: String, methodName: String, timestamp: Date, headers: [String: String] = [:], path: String = "", payload: String = "") {
//        self.accessKey = accessKey
//        self.secretKey = secretKey
//        self.host = host
//        self.region = region
//        self.service = service
//        self.methodName = methodName
//        self.headers = headers
//        self.timestamp = timestamp
//        self.payload = payload
//        self.path = path
//    }
//
//    func getHeaders() -> [String: String] {
//        let canonicalRequest = prepareCanonicalURL()
//        let stringToSign = prepareStringToSign(canonicalRequest: canonicalRequest)
//        let signingKey = getSignatureKey(dateStamp: xAmzDate, regionName: region, serviceName: service)
//        let signature = getSignature(signingKey: signingKey, stringToSign: stringToSign)
//
//        let authorizationHeader = "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeader), Signature=\(signature)"
//        headers["Authorization"] = authorizationHeader
//        return headers
//    }
//
//    private func prepareCanonicalURL() -> String {
//        let canonicalUri = "\(methodName)\n\(path)"
//        let payloadHash = payload.sha256()
//        let canonicalHeaders = headers.map { "\($0.key.lowercased()):\($0.value)" }.sorted().joined(separator: "\n")
//        let canonicalRequest = "\(canonicalUri)\n\n\(canonicalHeaders)\n\n\(signedHeader)\n\(payloadHash)"
//        return canonicalRequest
//    }
//
//    private func prepareStringToSign(canonicalRequest: String) -> String {
//        let hashedCanonicalRequest = canonicalRequest.sha256()
//        let stringToSign = "\(algorithm)\n\(xAmzDateTime)\n\(credentialScope)\n\(hashedCanonicalRequest)"
//        return stringToSign
//    }
//
//    private func getSignatureKey(dateStamp: String, regionName: String, serviceName: String) -> Data {
//        let dateKey = ("AWS4" + secretKey).hmac(algorithm: .SHA256, string: dateStamp)
//        let regionKey = dateKey.hmac(algorithm: .SHA256, string: regionName)
//        let serviceKey = regionKey.hmac(algorithm: .SHA256, string: serviceName)
//        let signingKey = serviceKey.hmac(algorithm: .SHA256, string: "aws4_request")
//        return signingKey
//    }
//
//    private func getSignature(signingKey: Data, stringToSign: String) -> String {
//        let signature = stringToSign.hmac(algorithm: .SHA256, key: signingKey)
//        return signature
//    }
//}
//
//extension String {
//    func sha256() -> String {
//        let data = self.data(using: .utf8)!
//        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
//        data.withUnsafeBytes {
//            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
//        }
//        return Data(hash).map { String(format: "%02x", $0) }.joined()
//    }
//
//    func hmac(algorithm: CCHmacAlgorithm, string: String) -> Data {
//        let key = Data(self.utf8)
//        let data = Data(string.utf8)
//
//        var hmacData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
//        _ = hmacData.withUnsafeMutableBytes { hmacBytes -> UInt8 in
//            key.withUnsafeBytes { keyBytes -> UInt8 in
//                data.withUnsafeBytes { dataBytes -> UInt8 in
//                    CCHmac(algorithm, keyBytes.baseAddress, key.count, dataBytes.baseAddress, data.count, hmacBytes.baseAddress)
//                    return 0
//                }
//            }
//        }
//        return hmacData
//    }
//}
//
//extension String {
//    func hmac(algorithm: CCHmacAlgorithm, key: Data) -> String {
//        let data = Data(self.utf8)
//        var hmacData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
//
//        _ = hmacData.withUnsafeMutableBytes { hmacBytes -> UInt8 in
//            key.withUnsafeBytes { keyBytes -> UInt8 in
//                data.withUnsafeBytes { dataBytes -> UInt8 in
//                    CCHmac(algorithm, keyBytes.baseAddress, key.count, dataBytes.baseAddress, data.count, hmacBytes.baseAddress)
//                    return 0
//                }
//            }
//        }
//        return hmacData.map { String(format: "%02x", $0) }.joined()
//    }
//}
//
//// Example usage
//let auth = AWSV4Auth(
//    accessKey: "your_access_key",
//    secretKey: "your_secret_key",
//    host: "your_host",
//    region: "your_region",
//    service: "your_service",
//    methodName: "GET",
//    timestamp: Date(),
//    headers: ["Content-Type": "application/json"],
//    path: "/your_path",
//    payload: "{}"
//)
//
//let headers = auth.getHeaders()
//print(headers)
//
//import Foundation
//
//class ApiClient {
//    private let accessKey: String
//    private let secretKey: String
//    private let host: String
//    private let region: String
//    private var defaultHeaders: [String: String] = [:]
//
//    init(accessKey: String, secretKey: String, host: String, region: String) {
//        self.accessKey = accessKey
//        self.secretKey = secretKey
//        self.host = host
//        self.region = region
//        self.defaultHeaders["User-Agent"] = "paapi5-swift-sdk/1.0.0"
//        // Additional default header setup...
//    }
//
//    func setDefaultHeader(name: String, value: String) {
//        self.defaultHeaders[name] = value
//    }
//
//    func callApi(endpoint: String, method: String, body: Data?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
//        guard let url = URL(string: "https://\(self.host)\(endpoint)") else { return }
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        request.allHTTPHeaderFields = defaultHeaders
//        request.httpBody = body
//
//        // AWS V4 signature needs to be added to the headers...
//        // This is a simplified example; you need to generate and add the signature.
//        
//        let session = URLSession.shared
//        let task = session.dataTask(with: request) { data, response, error in
//            completion(data, response, error)
//        }
//        task.resume()
//    }
//}
//
//// Example usage
//let client = ApiClient(accessKey: "your_access_key", secretKey: "your_secret_key", host: "your_host", region: "your_region")
//client.callApi(endpoint: "/your_endpoint", method: "GET", body: nil) { data, response, error in
//    if let error = error {
//        print("Error: \(error)")
//    } else if let data = data {
//        // Handle the data/response
//    }
//}
