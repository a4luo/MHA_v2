/*
 Author: Zhenyuan Bo
 File Description: presents the physiological level
 Date: Nov 23, 2020
 */

import UIKit

class PhysiologicalView: UIView {
    
    var path: UIBezierPath!
    
    var activityList:[Int] = []
    
    init(frame: CGRect, date: Date) {
        super.init(frame: frame)

        self.backgroundColor = .white
        
        let decodedData = Utils.loadDailyActivityResult(date: date)
        if let safeDecodedData = decodedData{
            for needType in Utils.PHY_NEEDS{
                if safeDecodedData[needType] != 0{
                    activityList.append(safeDecodedData[needType])
                }
            }
            activityList.sort(){$0 > $1}
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func createPhysiologicalLevel() {
        path = UIBezierPath()
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: 0.0, y: self.frame.size.height))
        path.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height))
        path.addLine(to: CGPoint(x: self.frame.size.width*9/11, y: 0.0))
        path.close()
    }
    
    
    override func draw(_ rect: CGRect) {
        
        self.createPhysiologicalLevel()
        
        Utils.hexStringToUIColor(hex: Utils.BASE_COLOUR).setFill()
        path.fill()

        if activityList.count>0{
            let gradient = CAGradientLayer()
            gradient.frame = path.bounds
            gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
            
            if activityList.count==1{
                gradient.locations = [0.0, 0.2]
            }else if activityList.count==2{
                gradient.locations = [0.0, 0.2, 0.4]
            }else if activityList.count==3{
                gradient.locations = [0.0, 0.2, 0.4, 0.6]
            }else if activityList.count==4{
                gradient.locations = [0.0, 0.2, 0.4, 0.6, 0.7]
            }else if activityList.count==5{
                gradient.locations = [0.0, 0.2, 0.4, 0.6, 0.7, 0.8]
            }else if activityList.count==6{
                gradient.locations = [0.0, 0.2, 0.4, 0.6, 0.7, 0.8, 0.9]
            }else{
                gradient.locations = [0.0, 0.2, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0]
            }
            
            var colors:[Any] = []
            var currColour:CGColor
            var j = 6
            for i in 0..<activityList.count{
                if i==0{
                    currColour = Utils.hexStringToUIColor(hex: Utils.PHY_NEED_COLOUR_LIST[j]).cgColor
                    colors.append(currColour)
                }else if activityList[i] != activityList[i-1]{
                    j -= 1
                    currColour = Utils.hexStringToUIColor(hex: Utils.PHY_NEED_COLOUR_LIST[j]).cgColor
                    colors.append(currColour)
                }else if activityList[i] == activityList[i-1]{
                    currColour = Utils.hexStringToUIColor(hex: Utils.PHY_NEED_COLOUR_LIST[j]).cgColor
                    colors.append(currColour)
                }
            }
            
            if activityList.count < 7{
                colors.append(Utils.hexStringToUIColor(hex: Utils.BASE_COLOUR).cgColor)
            }
            
            gradient.colors = colors
            
            let shapeMask = CAShapeLayer()
            shapeMask.path = path.cgPath
            
            gradient.mask = shapeMask
            self.layer.addSublayer(gradient)
        }
        
    }
 
}
