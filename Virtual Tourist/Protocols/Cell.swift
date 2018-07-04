//
//  Cell.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 7/3/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import UIKit

protocol Cell: class {
    static var reuseIdentifier: String { get }
}

extension Cell {
    static var reuseIdentifier: String {
        return "\(self)"
    }
}
