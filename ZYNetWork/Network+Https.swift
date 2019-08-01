//
//  NetWork+Credential.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/15.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import Moya

public extension Network.Configuration {

    enum HttpsCheckType {
        case doubleCheck // 双向认证
        case singleCheck // 单向认证（客户端认证）
        case none        // 不进行认证
    }
    
    struct HttpsConfig {
        var checkType : HttpsCheckType = .none
        var availableHosts : [String] = []
        var serverCertificateFileName : String = ""
        var clientPKCS12FileName : String = ""
        var clientPKCS12Passphrase : String = ""
    }
    
    //定义一个结构体，存储认证相关信息
    fileprivate struct IdentityAndTrust {
        var identityRef : SecIdentity
        var trust       : SecTrust
        var certArray   : AnyObject
    }

    func configHttpsCrendientialDelegate(forManager mgr : Moya.Manager) {
        mgr.delegate.sessionDidReceiveChallenge = { session, challenge in
            if self.httpsConfig.checkType == .doubleCheck {
                return self.doubleCheck(session: session, challenge: challenge)
            } else {
                return self.singleCheck(session: session, challenge: challenge)
            }
        }
    }
    
    fileprivate func doubleCheck(session : URLSession, challenge : URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // 认证服务器证书
            HSPrint("zy debug https 认证服务器证书")
            
            let serverTrust : SecTrust = challenge.protectionSpace.serverTrust!
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
            let certificateCopyData = SecCertificateCopyData(certificate)
            guard let remoteCertificateData = CFBridgingRetain(certificateCopyData) else {
                return (.cancelAuthenticationChallenge, nil)
            }
            guard let localServerCerPath = Bundle.main.path(forResource: self.httpsConfig.serverCertificateFileName, ofType: ".cer") else {
                return (.cancelAuthenticationChallenge, nil)
            }
            
            let localServerCerUrl = URL(fileURLWithPath: localServerCerPath)
            guard let localCertificateData = try? Data(contentsOf: localServerCerUrl) else {
                return (.cancelAuthenticationChallenge, nil)
            }
            
            if remoteCertificateData.isEqual(to: localCertificateData) {
                let credential = URLCredential(trust: serverTrust)
                challenge.sender?.use(credential, for: challenge)
                return (.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            } else {
                return (.cancelAuthenticationChallenge, nil)
            }
        }
            
        else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            // 认证客户端证书
            guard let idAndTrust = self.extractIdentity() else {
                return (.cancelAuthenticationChallenge, nil)
            }
            let urlCredential = URLCredential(identity: idAndTrust.identityRef,
                                              certificates: idAndTrust.certArray as? [AnyObject],
                                              persistence: URLCredential.Persistence.forSession)
            return (.useCredential, urlCredential)
        }
        return (.cancelAuthenticationChallenge, nil)
    }
    
    fileprivate func singleCheck(session : URLSession, challenge : URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && self.httpsConfig.availableHosts.contains(challenge.protectionSpace.host) {
            // 认证服务器证书
            HSPrint("zy debug https 认证服务器证书")
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            return (.useCredential, credential)
        }
            
        else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            // 认证客户端证书
            guard let idAndTrust = self.extractIdentity() else {
                return (.cancelAuthenticationChallenge, nil)
            }
            let urlCredential = URLCredential(identity: idAndTrust.identityRef,
                                              certificates: idAndTrust.certArray as? [AnyObject],
                                              persistence: URLCredential.Persistence.forSession)
            return (.useCredential, urlCredential)
        }
        return (.cancelAuthenticationChallenge, nil)
    }
    
    
    fileprivate func extractIdentity() -> IdentityAndTrust? {
        var identityAndTrust : IdentityAndTrust?
        
        var secError : OSStatus = errSecSuccess
        
        guard let path = Bundle.main.path(forResource: self.httpsConfig.clientPKCS12FileName, ofType: "p12") else {
            return nil
        }
        
        guard let PKCS12Data = NSData(contentsOfFile: path) else {
            return nil
        }
        let key : NSString = kSecImportExportPassphrase as NSString
        let options : NSDictionary = [key : self.httpsConfig.clientPKCS12Passphrase]
        var items : CFArray?
        secError = SecPKCS12Import(PKCS12Data, options, &items)
        if secError == errSecSuccess {
            guard let certItems = items else {
                return nil
            }
            let cerItemsArray : Array = certItems as Array
            let dic : AnyObject? = cerItemsArray.first
            if let certEntry : Dictionary = dic as? Dictionary<String, AnyObject> {
                // grab the identity
                let identityPointer : AnyObject? = certEntry["identity"]
                let secIdentityRef : SecIdentity = identityPointer as! SecIdentity
                
                // grab the trust
                let trustPointer : AnyObject? = certEntry["trust"]
                let trustRef : SecTrust = trustPointer as! SecTrust
                
                // grab the cert
                let chainPointerOptional : AnyObject? = certEntry["chain"]
                guard let chainPointer = chainPointerOptional else {
                    return nil
                }
                identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef,
                                                    trust: trustRef,
                                                    certArray: chainPointer)
                return identityAndTrust
            }
        }
        return nil
    }
}
