//
//  WorkTableViewCell.swift
//  Line Basher
//
//  Created by Gregory Smith on 5/27/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit

class WorkTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblMainTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
