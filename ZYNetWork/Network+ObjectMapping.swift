//
//  Network+ObjectMapping.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/26.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ObjectMapper
import Moya


extension Observable where Element == [String : Any] {
    
    func mapObject<T : Mappable>(_ type : T.Type) -> Observable<T?> {
        return self.map({ (dic) -> T? in
            return Mapper<T>().map(JSON: dic)
        })
    }
    
    func mapObjectArray<T : Mappable>(_ type : T.Type, keyPath : String) -> Observable<[T]> {
        return self.map({ (dic) -> [T] in
            var ret = [T]()
            if let arr = dic.value(keyPath: keyPath) as? [[String : Any]] {
                ret = Mapper<T>().mapArray(JSONArray: arr)
            }
            return ret
        })
    }
}


extension PrimitiveSequence where TraitType == SingleTrait, ElementType == [String : Any] {
    
    func mapObject<T : Mappable>(_ type : T.Type) -> Single<T?> {
        return self.asObservable().mapObject(type).asSingle()
    }
    
    func mapObjectArray<T : Mappable>(_ type : T.Type, keyPath : String) -> Single<[T]> {
        return self.asObservable().mapObjectArray(type, keyPath: keyPath).asSingle()
    }
    
}
