//
//  NetWork.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/11.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import Moya

public class Network {
    
    public class Util {
        
    }
    
    public enum TaskType {
        case post, get, uploadMutipart
    }

    
    typealias Provider = MoyaProvider<MultiTarget>
    typealias EndpointClosureType = (MultiTarget) -> Endpoint
    
    static let `default` : Network = {
        return Network(configuration: Configuration.default)
    }()
    
    var provider : Provider
    
    init(configuration : Configuration) {
        self.provider = MoyaProvider(configuration: configuration)
    }
}

public extension MoyaProvider where Target == MultiTarget {

    convenience init(configuration : Network.Configuration) {
        
        let endpointClosure : Network.EndpointClosureType = {
            target -> Endpoint in
            
            let originUrlStr = URL(target: target).absoluteString
            var newUrlStr = originUrlStr
            // 外部调用，对请求的url进行定制化更改
            if let operationUrlClosure = configuration.operatingRequestUrl {
                newUrlStr = operationUrlClosure(target)
            }
            
            // 重新声称 endpoint
            let endpoint = Endpoint(
                url: newUrlStr,
                sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
            
            return endpoint
                    .adding(newHTTPHeaderFields: configuration.headers)  // 添加公共请求头
                    .replacing(task: configuration.replacingTask(target))// 根据外部需要替换task
        }
        
        let requestClosure =  { (endpoint: Endpoint, closure: RequestResultClosure) -> Void in
            do {
                var request = try endpoint.urlRequest()
                
                request.timeoutInterval = configuration.requestTimeoutInterval
                
                closure(.success(request))
                
            } catch MoyaError.requestMapping(let url) {
                closure(.failure(.requestMapping(url)))
            } catch MoyaError.parameterEncoding(let error) {
                closure(.failure(.parameterEncoding(error)))
            } catch {
                closure(.failure(.underlying(error, nil)))
            }
        }
        
        self.init(endpointClosure: endpointClosure,
                  requestClosure: requestClosure,
                  callbackQueue: configuration.callbackQueue,
                  manager: configuration.managerClosure(),
                  plugins: configuration.plugins)
    }
}


