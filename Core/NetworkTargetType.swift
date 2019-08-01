//
//  NetworkTargetType.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/25.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import Moya

public protocol NetworkTargetType : TargetType {
    
    var taskType : Network.TaskType { get }
    
    var parameters : [String : Any] { get }
    
    var allowCache : () -> Bool { get }
    
    var cacheKey   : String { get }
    
    func storeResponse(_ response : Moya.Response)
    
    func getCachedResponse() -> Moya.Response?
    
    func removeCachedResponse()
    
}

extension TargetType {
    var taskType : Network.TaskType {
        if self is MultiTarget {
            let mutiTarget = self as! MultiTarget
            return mutiTarget.taskType
        }
        return .post
    }
    
    var parameters : [String : Any] {
        if self is MultiTarget {
            let mutiTarget = self as! MultiTarget
            return mutiTarget.parameters
        }
        return [:]
    }
}

extension MultiTarget {
    var taskType : Network.TaskType {
        if self.target is NetworkTargetType {
            let t = self.target as! NetworkTargetType
            return t.taskType
        }
        return .post
    }
    
    var parameters : [String : Any] {
        if self.target is NetworkTargetType {
            let t = self.target as! NetworkTargetType
            return t.parameters
        }
        return [:]
    }
}
