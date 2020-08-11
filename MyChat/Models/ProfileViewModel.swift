//
//  ProfileViewModel.swift
//  MyChat
//
//  Created by Aditya Ambekar on 12/08/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation


enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
