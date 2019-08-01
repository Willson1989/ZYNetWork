//
//  NetWork+Extensions.swift
//  HongHaiShow
//
//  Created by FN-273 on 2019/7/12.
//  Copyright © 2019 Showself. All rights reserved.
//

import Foundation
import RxSwift
import CommonCrypto
import Moya

extension Data {
    public init(hex: String) {
        self.init(Array<UInt8>(hex: hex))
    }
    public var bytes: Array<UInt8> {
        return Array(self)
    }
    public func toHexString() -> String {
        return bytes.toHexString()
    }
}

extension Array {
    public init(reserveCapacity: Int) {
        self = Array<Element>()
        self.reserveCapacity(reserveCapacity)
    }
    
    var slice: ArraySlice<Element> {
        return self[self.startIndex ..< self.endIndex]
    }
}

extension Array where Element == UInt8 {
    public init(hex: String) {
        self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }
    
    public func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}


extension Dictionary where Key == String, Value == Any {
    
    func value(keyPath : String, delimiter: String = ".") -> Any? {
        
        guard !keyPath.isEmpty else {
            return nil
        }
        
        guard keyPath.contains(delimiter) else {
            return self[keyPath]
        }
        
        let keys = keyPath.components(separatedBy: delimiter)
        
        guard !keys.isEmpty else {
            return self[keyPath]
        }
        
        var val : Any? = self[keys.first!]
        
        if keys.count <= 1 {
            return val
        }
        
        for i in 1 ..< keys.count {
            if val == nil {
                return nil
            }
            let k = keys[i]
            if let k_index = Int(k) {
                if let arr = val as? [Any] {
                    if (0 ..< arr.count).contains(k_index) {
                        val = arr[k_index]
                    } else {
                        return nil
                    }
                } else if let dic = val as? [String : Any] {
                    val = dic[k]
                } else {
                    return nil
                }
            }
            else {
                if let dic = val as? [String : Any] {
                    val = dic[k]
                } else {
                    return nil
                }
            }
        }
        return val
    }
}

extension PrimitiveSequence where TraitType == SingleTrait {
    /*
     为了防止多次订阅导致map的闭包被多次调用，这里调用shareReplay来共享状态
     先将 Single 转换成 Observable 然后调用了shareReplay 之后在转换回 Single
     */
    func shareReplay() -> Single<ElementType> {
        return asObservable().share(replay: 1, scope: .forever).asSingle()
    }
}


