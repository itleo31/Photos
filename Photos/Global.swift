//
//  Global.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation

var dayFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .none
    dateFormatter.doesRelativeDateFormatting = true
    return dateFormatter
}()
