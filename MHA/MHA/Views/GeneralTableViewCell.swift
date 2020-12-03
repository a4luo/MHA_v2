/*
 Author: Zhenyuan Bo
 File Description: creates general table cell
 Date: Dec 1, 2020
 */
import UIKit

class GeneralTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
