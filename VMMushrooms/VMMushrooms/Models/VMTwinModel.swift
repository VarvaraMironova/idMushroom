//
//  VMTwinModel.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 12/17/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import Foundation
import UIKit

struct VMTwinModel {
    var identifier          : String?
    var name                : String?
    var latinName           : String?
    var mushroomDescription : String?
    var distinction         : String? //disscribes difference between found mushroom and twin
                                      //discussed. Add after compiting infromation
    
    var edibility           : VMMushroomEdibility!
    
    public var image : UIImage? {
        if let identifier = identifier {
            return UIImage(named: (identifier) + "1.jpg")
        }
        
        return nil
    }
    
    init(identifier: String) {
        if let path = Bundle.main.path(forResource: "MushroomsCatalog", ofType: "plist") {
            if let productCatalog = NSDictionary(contentsOfFile: path) as? [String: [String: Any]] {
                if let product = productCatalog[identifier] {
                    self.identifier = identifier
                    name = product["localizedName"] as? String
                    latinName = product["latinName"] as? String
                    mushroomDescription = product["description"] as? String
                    edibility = (product["edibility"] as? String).map { VMMushroomEdibility(rawValue: $0)! }
                }
            }
        }
    }
    
}
