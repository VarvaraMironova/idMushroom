//
//  NSObject+ObjectDescription.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/29/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import Foundation

extension NSObject {
    var theClassName: String {
        return NSStringFromClass(type(of: self))
    }
}
