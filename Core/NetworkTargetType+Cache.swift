//
//  NetworkCachingKey.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/25.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import RxCocoa


extension NetworkTargetType {
    func requestAndCache() -> Single<Moya.Response> {
        let target = self
        return self.request().flatMap({ (response) -> Single<Moya.Response> in
            var ret = Single<Moya.Response>.just(response)
            let allowCache = target.allowCache()
            if allowCache {
                target.storeResponse(response)
            }
            if allowCache, let cachedResponse = target.getCachedResponse() {
                ret = ret.asObservable().startWith(cachedResponse).asSingle()
            }
            return ret
        })
    }
}

extension NetworkTargetType {
    
    /*
     以 method + 请求url + 参数json字符串 作为缓存key
     */
    var cacheKey : String {
        let endpoint = self.endpoint
        if let request = try? endpoint.urlRequest(), let body = request.httpBody, let paramsStr = String(data: body, encoding: .utf8) {
            return "\(self.method.rawValue):\(endpoint.url)?\(paramsStr)"
        }
        return "\(self.method.rawValue):\(endpoint.url)"
    }
    
    var endpoint: Endpoint {
        return Endpoint(url: URL(target: self).absoluteString,
                        sampleResponseClosure: { .networkResponse(200, self.sampleData) },
                        method: self.method,
                        task: self.task,
                        httpHeaderFields: self.headers)
    }
    
    
    // 是否允许缓存，默认是不缓存
    var allowCache : () -> Bool {
        return { return true }
    }
    
    func storeResponse(_ response : Moya.Response) {
        
        MoyaTempPrint("zy debug moya 缓存 response, key : \(self.cacheKey)")
        
    }
    
    func getCachedResponse() -> Moya.Response? {
        
        MoyaTempPrint("zy debug moya 读取缓存, key : \(self.cacheKey)")
        return Moya.Response(statusCode: 200, data: Data())
    }
    
    func removeCachedResponse() {
        
        MoyaTempPrint("zy debug moya 删除缓存, key : \(self.cacheKey)")
    }
}

