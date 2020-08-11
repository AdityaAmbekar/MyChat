//
//  LocationModel.swift
//  MyChat
//
//  Created by Aditya Ambekar on 12/08/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

struct Location: LocationItem {
    
    var location: CLLocation
    var size: CGSize
}

