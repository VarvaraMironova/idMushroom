//
//  VMMushroomModel.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/16/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

enum VMMushroomEdibility: String {
    case deadly                 = "deadly"
    case poisonous              = "poisonous"
    case psychoactive           = "poisonous (psychoactive)"
    case choice                 = "choice"
    case not_recommended        = "edible but not recommended"
    case edible_inedible        = "edible / inedible"
    case inedible               = "inedible"
    case suspect                = "suspect"
    case edible                 = "edible"
}

class VMMushroomModel: NSObject {
    var identifier          : String
    var name                : String!
    var latinName           : String!
    var mushroomDescription : String!
    
    var edibility           : VMMushroomEdibility!
    
    var twins  = [VMMushroomModel]()
    var images = [UIImage]()
    
    let imagesCount = 4
    
    deinit {
        self.name = nil
        self.latinName = nil
        self.edibility = nil
        self.mushroomDescription = nil
    }
    
    init(identifier: String) {
        self.identifier = identifier
        
        if let path = Bundle.main.path(forResource: "MushroomsCatalog", ofType: "plist") {
            if let productCatalog = NSDictionary(contentsOfFile: path) as? [String: [String: Any]] {
                if let product = productCatalog[identifier] {
                    self.name = product["localizedName"] as? String
                    self.latinName = product["latinName"] as? String
                    self.mushroomDescription = product["description"] as? String
                    
                    self.edibility = product["edibility"] as? VMMushroomEdibility
                }
            }
        }
        
        for i in 1...imagesCount {
            if let productImage = UIImage(named: (identifier as String) + String(i) + ".jpg") {
                images.append(productImage)
            }
        }
    }
}
