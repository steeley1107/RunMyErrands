//
//  CustomInfoWindow.swift
//  RunMyErrands
//
//  Created by Steele on 2015-12-02.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit

class CustomInfoWindow: UIView {
    

    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var snippit: UILabel!
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var bubbleLeft: UIImageView!
    @IBOutlet weak var bubbleRight: UIImageView!
    
    
    override func awakeFromNib() {
        
        
        
//        let insetsLeft = UIEdgeInsetsMake(0, 0, 55, 30)
//        let insetsRight = UIEdgeInsetsMake(0, 30, 55, 0)
//
//        
//        
//        bubbleLeft.image = bubbleLeft.image?.resizableImageWithCapInsets(insetsLeft)
//
//        bubbleRight.image = bubbleRight.image?.resizableImageWithCapInsets(insetsRight)

    }
}
