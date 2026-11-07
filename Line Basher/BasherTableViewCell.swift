//
//  BasherTableViewCell.swift
//  Line Basher
//
//  Created by Gregory Smith on 5/27/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit

class BasherTableViewCell: UITableViewCell
{
    
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var btnRehearse: UIButton!
    @IBOutlet weak var lblLines: UILabel!
    @IBOutlet weak var btnCopyLine: UIButton!
    
    //var delegate: LineCopyProtocol?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        lblLines.textAlignment = .center
        lblLines.minimumScaleFactor = 0.5
        
        btnRehearse.alpha = 0
        btnEdit.alpha = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func btnCopyLineAction(_ sender: Any)
    {
        dbObj.copyLineToDatabase(lineToCopy: dbObj.currentLine)
        dbObj.loadLineArrayFromDB()                                     //Need to do this to ensure renumbering works properly.
        dbObj.reNumberLinesInArrayAndSaveToDataBase()
        dbObj.loadLineArrayFromDB()                                     //Need to do this to display correct renumbered array.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: reloadNotificationString), object: nil)

        //delegate?.lineReloadData()
    }
}

let reloadNotificationString: String = "reloadNotificationString"

//protocol LineCopyProtocol
//{
//    func lineReloadData()
//}
