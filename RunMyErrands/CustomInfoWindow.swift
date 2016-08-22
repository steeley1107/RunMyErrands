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
    
    @IBOutlet weak var snippet: UILabel!
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var bubbleLeft: UIImageView!
    @IBOutlet weak var bubbleRight: UIImageView!
    
    @IBOutlet weak var view: UIView!
    
    
    override func awakeFromNib() {

    }
}
