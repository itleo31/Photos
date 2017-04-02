//
//  Misc.swift
//  Photos
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let livePhotoIcon = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
}



func log(_ message: String) {
    print(message)
}

func dispatchBackground(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.global().async(execute: work)
}
