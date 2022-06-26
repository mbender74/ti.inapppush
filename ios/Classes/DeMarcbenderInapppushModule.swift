//
//  DeMarcbenderInapppushModule.swift
//  ti.inapppush
//
//  Created by Marc Bender
//  Copyright (c) 2022 Your Company. All rights reserved.
//

import TitaniumKit

enum Environment {
    case delelopment
    case production
}

enum AuthenticationMethod {
    case tokenBased
}


@objc(DeMarcbenderInapppushModule)
class DeMarcbenderInapppushModule: TiModule {
   
    public var _cerName: String?
    public var _lastSelectCerPath: String?
    public var _p8FilePath: String = ""
    public var _p8PrivateKey: String?
    public var _p8FileName: String = ""
    public var _jwtToken: JWT.Token!
    public var deviceTokenString: String?
    public var isConnected: Bool = false
    public var socket: Socket?
    public var session: URLSession = .shared
    public var userDefaults: UserDefaults = .standard
    public var _env: Environment = .delelopment
    public var _authMethod: AuthenticationMethod = .tokenBased
    public let currentSecKey = "lastSelected"

    public var environment: String?
    public var keyId: String?
    public var teamId: String?
    public var bundleId: String?
    public var bundleIdTextField: String?
    public var deviceTokenTextField: String?
    public var payloadTextField: String?
    public var keyIdTextField: String?
    public var teamIdTextField: String?

    public let CertificateAppleDelelopmentPushHost = "gateway.sandbox.push.apple.com"
    public let CertificateAppleProductionPushHost = "gateway.push.apple.com"
    public let CertificateApplePushPort: Int = 2195

    public let TokenAuthenticationAppleDelelopmentPushHost = "api.development.push.apple.com"
    public let TokenAuthenticationAppleProductionPushHost = "api.push.apple.com"
    public let TokenAuthenticationApplePushScheme = "https"
    public let TokenAuthenticationApplePushPort: Int = 443

  
  func moduleGUID() -> String {
    return "f0da180b-c0e0-4f05-99e4-673bde9aba3c"
  }
  
  override func moduleId() -> String! {
    return "de.marcbender.inapppush"
  }

  override func startup() {
    super.startup()
      NSLog("[DEBUG] \(self) loaded")
  }
 
  private func TokenAuthenticationApplePushPath(withDeviceToken deviceToken: String) -> String {
    return "/3/device/\(deviceToken)"
  }
    
  @objc(setupPush:)
  public func setupPush(arguments: [AnyHashable : Any]!) {
      let params = arguments
        
      if params!["keyId"] != nil {
          keyId = TiUtils.stringValue(params!["keyId"])
      }
      if params!["teamId"] != nil {
          teamId = params!["teamId"] as? String
      }
      if params!["bundleId"] != nil {
          bundleId = params!["bundleId"] as? String
      }
      if params!["environment"] != nil {
          environment = params!["environment"] as? String
          if (environment == "development") {
              _env = .delelopment
          }
          else {
             _env = .production
          }
      }
      if params!["p8FilePath"] != nil {
          _p8FilePath = (params!["p8FilePath"] as? String)!
          let fileURL = URL(fileURLWithPath: _p8FilePath)
          _p8FileName = fileURL.lastPathComponent
          _p8PrivateKey = try? P8.getPrivateKey(fromP8: _p8FilePath)
      }
      resetConnect()
  }
    
  @objc(sendPushToUser:)
  public func sendPushToUser(arguments: Array<Any>?) {
        guard let params = arguments?.first as? [String: Any] else {
            return
        }
        var payloadType:String!
        var deviceToken:String!
        var payload:String!
        var callback:KrollCallback? = nil
            
        if params["callback"] != nil {
            callback = (params["callback"] as? KrollCallback)!
        }
        if params["deviceToken"] != nil {
            deviceToken = (params["deviceToken"] as? String)!
        }
        if params["payloadType"] != nil {
            payloadType = (params["payloadType"] as? String)!
        }
        else {
            payloadType = "alert"
        }
        if params["payload"] != nil {
            payload = jsonToString(json: params["payload"] as AnyObject)
            if (payload == ""){
                payload = nil
            }
        }

        // Validate input
        guard !_p8FilePath.isEmpty else {
            return
        }
        
        guard !bundleId!.isEmpty else {
            return
        }
        
        // A 10-character key identifier (kid) key, obtained from your developer account
        guard keyId!.count == 10 else {
            return
        }
        
        // The issuer (iss) registered claim key, whose value is your 10-character Team ID, obtained from your developer account
        guard teamId!.count == 10 else {
            return
        }
        if (deviceToken != nil && payload != nil){
            let jwtToken: JWT.Token
            if let token = _jwtToken, !token.isExpired {
                jwtToken = token
            } else {
                let authToken = AuthenticationToken(keyId: keyId!, teamId: teamId!)
                if let privateKey = _p8PrivateKey {
                    jwtToken = try! authToken.generateJWTToken(fromP8PrivateKey: privateKey)
                } else {
                    jwtToken = try! authToken.generateJWTToken(fromP8: _p8FilePath)
                }
            }
           
            let newDeviceToken = deviceToken.replacingOccurrences(of: " ", with: "")
            let url = tokenAuthenticationApplePushURL(with: _env, deviceToken: newDeviceToken)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(bundleId, forHTTPHeaderField: "apns-topic")
            request.setValue(payloadType, forHTTPHeaderField: "apns-push-type")
            request.httpBody = payload.data(using: .utf8)
            
            let task = session.dataTask(with: request) { (data, response, error) in
                let statusCode = (response as! HTTPURLResponse).statusCode
                var reason: String?
                if let data = data, let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    print("response dict: \(dict)")
                    reason = dict["reason"] as? String
                }
                var errmsg: String?
                
                if statusCode == 200 {
                    errmsg = "success"
                } else {
                    errmsg = reason ?? error!.localizedDescription
                }
                if ((callback) != nil){
                    callback!.call([["result": errmsg]], thisObject: self)
                }
            }
            task.resume()
        }
        else {
            if ((callback) != nil){
                callback!.call([["result": "missing deviceToken and payload"]], thisObject: self)
            }
            else {
                return
            }
        }
    }
    
    func jsonToString(json: AnyObject) -> String {
            do {
                let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
                let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
                return convertedString! as String // <-- here is ur string

            } catch let myJSONError {
                print(myJSONError)
                return ""
            }
    }
    
    func disconnect(force: Bool) {
        
        // Close connection to server.
        socket?.disconnect(force: force)
        isConnected = false
    }
    
    func resetConnect() {
        disconnect(force: true)
    }
        
    func certificateApplePushHost(with env: Environment) -> String {
        switch env {
        case .delelopment:
            return CertificateAppleDelelopmentPushHost
        case .production:
            return CertificateAppleProductionPushHost
        }
    }
    
    func certificateApplePushPort(with env: Environment) -> Int {
        return CertificateApplePushPort
    }
    
    /// See [Communicating with APNs](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html#//apple_ref/doc/uid/TP40008194-CH11-SW1)
    func tokenAuthenticationApplePushURL(with env: Environment, deviceToken: String) -> URL {
        let host: String

        print("[INFO] tokenAuthenticationApplePushURL")


        switch env {
        case .delelopment:
            host = TokenAuthenticationAppleDelelopmentPushHost
        case .production:
            host = TokenAuthenticationAppleProductionPushHost
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = TokenAuthenticationApplePushScheme
        urlComponents.host = host
        urlComponents.port = TokenAuthenticationApplePushPort
        urlComponents.path = TokenAuthenticationApplePushPath(withDeviceToken: deviceToken)
        
        guard let url = urlComponents.url else {
            fatalError()
        }
        
        return url
    }
}
