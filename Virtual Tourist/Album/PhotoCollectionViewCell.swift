//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 6/23/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell, Cell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
