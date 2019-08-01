//
//  NetWork+Configuration.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/12.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import Moya

public extension Network {
    
    class Configuration {
        
        /**
         https 证书校验相关的配置
         */
        var httpsConfig = HttpsConfig()
        
        /**
         回调的队列，默认是主队列
         */
        var callbackQueue : DispatchQueue = DispatchQueue.main
        
        /**
         请求超时时间，默认60秒
         */
        var requestTimeoutInterval : TimeInterval = 60
        
        /**
         公共的请求头
         */
        var headers : [String : String] = [:]
        
        /**
         针对 AlamofireManager 进行定制化的闭包
         */
        var managerClosure : (() -> Manager) = {
            return Provider.defaultAlamofireManager()
        }
        
        /**
         对 TargetType 的task进行定制化，例如可以根据需要将现有的task转换成另一种task
         或者可以在这个闭包中针对task中的参数进行定制化操作
         */
        var replacingTask : (_ target : TargetType) -> Task = { target in
            return target.task
        }
        
        /**
         对请求 url 进行定制化的闭包，例如在 url 上面添加公共参数，替换url中的某一部分等等。
         */
        var operatingRequestUrl : (( _ target : TargetType) -> String)?
        
        var commonParametersClosure : ((_ target : TargetType) -> [String : Any])?
        
        private var innerCommonParam : [String : Any]?
        
        func commonParameters(target : TargetType) -> [String : Any] {
            if let ret = self.innerCommonParam {
                return ret
            } else {
                let commParams = self.commonParametersClosure?(target) ?? [:]
                self.innerCommonParam = commParams
                return commParams
            }
        }
        
        var plugins : [PluginType] = []
        
        static let `default` : Configuration = {
            return Configuration()
        }()
        
    }
}
