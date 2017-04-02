//
//  RxExt.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation

extension Observable {
    public func observeOnMain() -> Observable<Element> {
        return observeOn(MainScheduler.instance)
    }
}
