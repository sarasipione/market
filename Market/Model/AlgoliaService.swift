//
//  AlgoliaService.swift
//  Market
//
//  Created by Sara Sipione on 25/11/2019.
//  Copyright © 2019 Sara Sipione. All rights reserved.
//

import UIKit
import InstantSearchClient

class AlgoliaService {
    static let shared = AlgoliaService()
    
    let client = Client(appID: kALGOLIA_APP_ID, apiKey: kALGOLIA_ADMIN_KEY)
    let index = Client(appID: kALGOLIA_APP_ID, apiKey: kALGOLIA_ADMIN_KEY).index(withName: "item_Name")
    
    private init() {
    }
}
