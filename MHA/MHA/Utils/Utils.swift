import UIKit
import Foundation

class Utils{
    
    //MARK: - Segue Identifiers
    public static let signinSegue = "SigninToHistory"
    public static let registerSegue = "RegisterToHistory"
    public static let dailyNotesSegue = "CalendarToDailyNotes"
    public static let userInputSegue = "NotesToUserInput"
    
    //MARK: - Reusable Cell Identifiers
    public static let weekCell = "WeekCell"
    public static let monthCell = "MonthCell"
    
    //MARK: - Bar Item Button Actions
    public static let addNoteMsg = "Add New Note"
    public static let alertAddAction = "Add"
    public static let cellNibName = "NoteActivityCell"
    
    //MARK: - Screen Scroll Direction
    public static let downDirection = "down"
    public static let upDirection = "up"
    
    //MARK: - WEEK & Month
    public static let weekDayMap = [ 1:"Sun", 2:"Mon", 3:"Tue", 4:"Wed", 5:"Thur", 6:"Fri", 7:"Sat" ]
    public static let monthMap = [1:"Jan", 2: "Feb", 3: "Mar", 4:"Apr",
                                  5:"May", 6:"Jun", 7:"Jul",
                                  8:"Aug", 9: "Sept", 10: "Oct", 11: "Nov", 12: "Dec"]
    public static let monthColourMap = ["Jan": "006EAC", "Feb":"E1E0E5",
                                        "Mar":"61D200", "Apr": "4CB0B2",
                                        "May":"F4736E", "Jun":"FFA800",
                                        "Jul":"FFFFFF", "Aug":"BA9389",
                                        "Sept":"CAA301", "Oct":"F45F22",
                                        "Nov":"DCAF9F", "Dec":"949BA5"]
}



enum CellType: String{
    case week
    case month
}

enum CellContent{
    case weekRange(String, String, Date, Date)
    case monthImg(UIImage)
}


//MARK: - Date Extension

extension Date {
    
    func firstDayOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year,.month], from: self)
        guard let date = calendar.date(from: components) else {
            fatalError("First day of month doesn't exist!")
        }
        return date
    }
    
    func lastDayOfMonth() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.day = -1
        guard let date = calendar.date(byAdding: components, to: self.firstDayOfMonth()) else {
            fatalError("Last day of month doesn't exist!")
        }
        return date
    }
    
    func firstDayOfWeek() -> Date {
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        guard let date = calendar.date(from: components) else {
            fatalError("First day of week doesn't exist!")
        }
        return date
    }
    
    func lastDayOfWeek() -> Date {
        let calendar = Calendar(identifier: .iso8601)
        var components = DateComponents()
        components.weekOfYear = 1
        components.day = -1
        guard let date = calendar.date(byAdding: components, to: self.firstDayOfWeek()) else {
            fatalError("Last day of week doesn't exist!")
        }
        return date
    }
    
    func daysOffset(by: Int) -> Date {
        return Date(timeInterval: Double(by * 24 * 60 * 60), since: self)
    }
    
    func numOfDaysInMonth() -> Int {
        let range = Calendar.current.range(of: .day, in: .month, for: self)
        guard let count = range?.count else {
            fatalError("Number of month doesn't exist!")
        }
        return count
    }
    
    func dateFormatter(format: String) -> String {
        let f = DateFormatter()
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = format
        return f.string(from: self)
    }
}

//MARK: - Hex to UIColor
func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}