//
//  ImageCollectionViewCell.swift
//  Market
//
//  Created by Sara Sipione on 23/11/2019.
//  Copyright © 2019 Sara Sipione. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setUpImageWith(itemImage: UIImage) {
        imageView.image = itemImage
    }
}
