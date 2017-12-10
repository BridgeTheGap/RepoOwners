//
//  RepoOwner.swift
//  RepoOwners
//
//  Created by Joshua Park on 10/12/2017.
//  Copyright © 2017 Joshua Park. All rights reserved.
//

import Foundation

struct RepoOwner: Hashable {
    
    static func ==(lhs: RepoOwner, rhs: RepoOwner) -> Bool {
        return lhs.avatarURL == rhs.avatarURL &&
            lhs.name == rhs.name
    }
    
    var hashValue: Int {
        let const = 0x7FFF_FFFF_FFFF_FFFF
        return avatarURL.hash & const +
            name.hash & const
    }
    
    let avatarURL: String
    let name: String
    
}
