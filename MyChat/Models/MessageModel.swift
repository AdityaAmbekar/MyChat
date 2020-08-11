//
//  MessageTypeModel.swift
//  MyChat
//
//  Created by Aditya Ambekar on 12/08/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation
import MessageKit

struct Message: MessageType {
    
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}
