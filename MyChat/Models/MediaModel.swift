//
//  MediaItemModel.swift
//  MyChat
//
//  Created by Aditya Ambekar on 12/08/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation
import MessageKit

struct Media: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}
