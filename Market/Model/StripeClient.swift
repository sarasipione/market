//
//  StripeClient.swift
//  Market
//
//  Created by Sara Sipione on 26/11/2019.
//  Copyright © 2019 Sara Sipione. All rights reserved.
//

import UIKit
import Stripe
import Alamofire

class StripeClient {
    static let sharedClient = StripeClient()
    
    var baseURLString: String? = nil
    
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    func createAndConfirmPayment(_ token: STPToken, amount: Int, completion: @escaping(_ error: Error?) -> Void) {
        let url = self.baseURL.appendingPathComponent("charge")
        let params: [String: Any] = ["stripeToken": token.tokenId,
                                     "amount": amount,
                                     "description": Constants.defaultDescription,
                                     "currency": Constants.defaultCurrency]
        
        Alamofire.request(url, method: .post, parameters: params).validate(statusCode: 200..<300).responseData { (response) in
            switch response.result {
            case .success( _):
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
}
