//
// Created by Anders Carlsson on 09/01/16.
// Copyright (c) 2016 CoreDev. All rights reserved.
//

import Foundation

public enum Queue {

    private static let mainQueue = dispatch_get_main_queue()
    private static let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

    public static func main(block: dispatch_block_t) {
        dispatch_async(mainQueue, block)
    }

    public static func background(block: dispatch_block_t) {
        dispatch_async(backgroundQueue, block)
    }
}
