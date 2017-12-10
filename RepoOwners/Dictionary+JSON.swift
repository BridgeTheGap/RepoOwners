//
//  Dictionary+JSON.swift
//  RepoOwners
//
//  Created by Joshua Park on 11/12/2017.
//  Copyright © 2017 Joshua Park. All rights reserved.
//

import Foundation

//
//  Dictionary+JSON.swift
//  EdgeJSON
//
//  Created by Joshua Park on 07/10/2017.
//  Copyright © 2017 Edge. All rights reserved.
//

import Foundation

public extension Dictionary {
    
    public func bool(_ key: Key) -> Bool? {
        return self[key] as? Bool
    }
    
    public func int(_ key: Key) -> Int? {
        return self[key] as? Int
    }
    
    public func double(_ key: Key) -> Double? {
        return self[key] as? Double
    }
    
    public func str(_ key: Key) -> String? {
        return self[key] as? String
    }
    
    public func nilStr(_ key: Key) -> String? {
        guard let str = self[key] as? String else { return nil }
        return str.count > 0 ? str : nil
    }
    
    public func dic(_ key: Key) -> [String: Any]? {
        return self[key] as? [String: Any]
    }
    
    public func arr(_ key: Key) -> [Any]? {
        return self[key] as? [Any]
    }
    
    public func dicArr(_ key: Key) -> [[String: Any]]? {
        return self[key] as? [[String: Any]]
    }
    
    public func arrArr(_ key: Key) -> [[Any]]? {
        return self[key] as? [[Any]]
    }
    
}
