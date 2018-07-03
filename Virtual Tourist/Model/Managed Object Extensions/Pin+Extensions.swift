//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 6/23/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
