//
//  MenuTableViewCell.swift
//  Identy1
//
//  Created by mac on 6/11/18.
//  Copyright © 2018 Sumuga. All rights reserved.
//

import UIKit
class MenuTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkBoxButton: UIButton!
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    static var identifier: String {
        return String(describing: self)
    }
    static var cellSize:CGFloat {
        return 44.0
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
