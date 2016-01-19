//
//  ZipCodeValidator.swift
//  Movement
//
//  Created by Susan Crayne on 1/18/16.
//  Copyright © 2016 Coders For Sanders. All rights reserved.
//

import Foundation
import CoreLocation

class ZipCodeValidator {
    
    init() { 
    }
    
    
    func validate(zip: String) -> Bool{
        var rtn = true;
        if (zip.characters.count != 5) {
            rtn = false
        }
        //Check for numeric
        let convertedZip = Double(zip)
        if (convertedZip == nil){
            rtn = false
        }
        if (rtn == false){
            let alert = UIAlertView()
            alert.title = "Invalid zip code"
            alert.message = "The zip code must be exactly 5 numbers"
            alert.addButtonWithTitle("Ok")
            alert.show()
            return false
        }
        else {
            return true
        }
    }
}