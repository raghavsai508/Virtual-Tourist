//
//  TravelAnnotation.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 6/21/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import UIKit
import MapKit

class TravelAnnotation: NSObject, MKAnnotation {

    let travelId: String?
    let coordinate: CLLocationCoordinate2D
    
    init(travelId: String, coordinate: CLLocationCoordinate2D) {
        self.travelId = travelId
        self.coordinate = coordinate
        super.init()
    }
    
}
