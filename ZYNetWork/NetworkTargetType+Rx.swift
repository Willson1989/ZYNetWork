//
//  TargetType+Rx.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/12.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import RxSwift
import Moya

public extension NetworkTargetType {
    
    /**
     subscribeOnSuccess   : 请求成功的回调
     subscribeOnError     : 请求错误的回调
     */
    func request() -> Single<Moya.Response> {
        return Network.default.provider.rx.request(MultiTarget.target(self))
    }

    
    /**
     subscribeOnNext      : progress进度的回调
     subscribeOnCompleted : 请求完成（进度100%）的回调
     subscribeOnError     : 请求错误的回调
     */
    func requestWithProgress() -> Observable<Moya.ProgressResponse> {
        return Network.default.provider.rx.requestWithProgress(MultiTarget.target(self))
    }
}





