//
//  FirebaseCollectionReference.swift
//  Market
//
//  Created by Sara Sipione on 22/11/2019.
//  Copyright © 2019 Sara Sipione. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
    case User
    case Category
    case Items
    case Basket
}

func FirebaseReference(_ collectionReference: FCollectionReference) -> CollectionReference {
    return Firestore.firestore().collection(collectionReference.rawValue)
}
