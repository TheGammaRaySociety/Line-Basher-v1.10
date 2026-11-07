//
//  SceneTableViewCell.swift
//  Line Basher
//
//  Created by Gregory Smith on 6/28/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit

class SceneTableViewCell: UITableViewCell {

    @IBOutlet weak var lblSceneName: UILabel!
    @IBOutlet weak var lblSceneLines: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
