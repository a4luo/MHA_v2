import UIKit
import RealmSwift

class UserInputViewController: UIViewController, UITabBarDelegate{
    
    private var savedActivityText: String?
    private var activityID: String?
    private var readonly: Bool = true
    private var selectedDate: Date = Date()
    
    private var colours = ["#9ad3bc","#fd8c04", "#9088d4", "#f3bad6", "#9ddfd3",
                           "#ffa36c", "#bedbbb", "#0e918c", "#a6f6f1", "#edcfa9"]
    
    @IBAction func unwind(_ unwindSegue: UIStoryboardSegue) {
        if let calendarViewController = unwindSegue.source as? CalendarViewController{
            if let safeSelectedActivityText = calendarViewController.selectedActivitiyText{
                savedActivityText = safeSelectedActivityText
            }else{
                savedActivityText = ""
            }
            if let safeSelectedDate = calendarViewController.selectedDate{
                selectedDate = safeSelectedDate
            }
        }
    }
    
    let realm = try! Realm()
    let encoder = JSONEncoder()
    
    @IBOutlet weak var userInputTabBar: UITabBar!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var flashCard: FlashCardView!
    
    //MARK: - User Input Outlet
    @IBOutlet weak var activityText: UITextView!
    @IBOutlet weak var flipButton: UIBarButtonItem!
    
    //    private var dailyNeedMap:[String:Bool] = [:]
    private var dailyActivityMap:[String:Int] = [:]
    private var selectedNeeds: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for need in Utils.needTypeList{
            dailyActivityMap[need] = 0
        }
        
        userInputTabBar.delegate = self
        
        self.view.addGestureRecognizer(leftSwipeGestureRecognizer)
        self.view.addGestureRecognizer(rightSwipeGestureRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = setTitle(date: selectedDate)
        
        if let safeActivityText = savedActivityText{
            activityText.text = safeActivityText
            if safeActivityText != ""{
                activityID = loadActivityID(activityText: safeActivityText)
            }else{
                activityID = UUID.init().uuidString
            }
        }else{
            activityID = UUID.init().uuidString
        }
        
        readonly = true
        populateDailyActivityMap(date: selectedDate)
        cleanPyramidMapData()
        populateSelectedNeed(activityID: activityID!)
        
        flashCard.duration = 2.0
        flashCard.flipAnimation = .flipFromLeft
        flashCard.frontView = frontView
        flashCard.backView = backView
        activityText.font = .systemFont(ofSize: 18)
    }
    
    //MARK: - Button Actions
    @IBAction func flipPressed(_ sender: UIBarButtonItem) {
        flashCard.flip()
        if flashCard.backView!.isHidden && !readonly{
            print("save...")
            //            saveDailyNeedMap(date: selectedDate)
            saveDailyActivityMap(date: selectedDate)
            saveSelectedNeeds()
        }
    }
    
    @IBAction func needButtonPressed(_ sender: UIButton) {
        var selectedCategory = sender.titleLabel?.text
        readonly = false
        if selectedCategory! == "personal security"{
            selectedCategory = "personal_security"
        }else if selectedCategory! == "self-esteem"{
            selectedCategory = "self_esteem"
        }else if selectedCategory! == "Self Actualization"{
            selectedCategory = "self_actualization"
        }
        if sender.titleColor(for: .normal) == UIColor.white{
            sender.setTitleColor(.black, for: .normal)
            //            dailyNeedMap[selectedCategory!] = true
            selectedNeeds += " " + selectedCategory!
            dailyActivityMap[selectedCategory!]! += 1
        }else{
            sender.setTitleColor(.white, for: .normal)
            //            dailyNeedMap[selectedCategory!] = false
            dailyActivityMap[selectedCategory!]! -= 1
        }
    }
    
    @IBAction func deletePressed(_ sender: UIBarButtonItem) {
        var activityToDeleteDateCreated = ""
        
        let activityToDelete = realm.objects(Activity.self).filter("activityID = '\(activityID!)'")
        
        if activityToDelete.count>0{
            activityToDeleteDateCreated = activityToDelete[0].dateCreated
            
            let activityNeedToDelete = realm.objects(ActivityNeed.self).filter("activityID='\(activityID!)'")
            
            if activityNeedToDelete.count>0{
                let selectedNeedsToDelete = activityNeedToDelete[0].selectedNeeds
                let selectedNeedsToDeleteArray = selectedNeedsToDelete.components(separatedBy: " ")
                
                let dailyActivityToModify = realm.objects(DailyActivity.self).filter("dateCreated = '\(activityToDeleteDateCreated)'")
                if dailyActivityToModify.count>0{
                    let result = dailyActivityToModify[0].numActivityResult
                    let jsonData = result.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    do{
                        let decodedData = try decoder.decode(DailyActivityData.self, from: jsonData)
                        var newData:[String:Int] = [:]
                        for need in Utils.needTypeList{
                            if selectedNeedsToDeleteArray.contains(need){
                                newData[need] = decodedData[need]-1
                            }else{
                                newData[need] = decodedData[need]
                            }
                        }
                        if let newJSONData = try? encoder.encode(newData){
                            if let jsonString = String(data: newJSONData, encoding: .utf8){
                                do{
                                    try self.realm.write{
                                        let newDailyActivity = DailyActivity()
                                        newDailyActivity.dateCreated = activityToDeleteDateCreated
                                        newDailyActivity.numActivityResult = jsonString
                                        realm.add(newDailyActivity, update: .modified)
                                        realm.delete(activityToDelete[0])
                                        realm.delete(activityNeedToDelete[0])
                                    }
                                }catch{
                                    print("Error saving modified daily activity object, \(error)")
                                }
                            }
                        }
                    }catch{
                        print("Error retrieving decoded need DailyActivity data, \(error)")
                    }
                }
            }
        }else{
            print("No such activity with ID: \(activityID!) to be deleted")
        }
    }
    
    
    @IBAction func savePressed(_ sender: UIBarButtonItem) {
        showTimePicker()
    }
    
    @IBAction func addPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Do you want to save current note?", message: "", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            self.showTimePicker()
            self.activityText.text = ""
            self.cleanPyramidMapData()
        }
        let newAction = UIAlertAction(title: "No", style: .default) { (action) in
            self.activityText.text = ""
            self.cleanPyramidMapData()
        }
        alert.addAction(saveAction)
        alert.addAction(newAction)
        present(alert, animated: true, completion: nil)
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "Calendar"{
            performSegue(withIdentifier: Utils.userInputCalendarSegue, sender: self)
        }else if item.title == "Report"{
            performSegue(withIdentifier: Utils.userInputReportSegue, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Utils.userInputReportSegue{
            let destinationVC = segue.destination as! ResultsViewController
            destinationVC.selectedDate = selectedDate
        }
    }
    
    //MARK: - Data Manipulation Methods
    private func setTitle(date: Date)->String{
        let month = date.dateFormatter(format: "MM")
        let monthName = Utils.monthMap[Int(month)!]!
        let dateNumber = date.dateFormatter(format: "d")
        let navBartitle = "\(monthName) \(dateNumber)"
        return navBartitle
    }
    
    private func saveActivity(startTime: String, endTime: String){
        do{
            try self.realm.write{
                let newActivity = Activity()
                newActivity.dateCreated = selectedDate.dateFormatter(format: "yyyy-MM-dd")
                newActivity.activityText = self.activityText.text
                newActivity.activityID = activityID!
                newActivity.startTime = startTime
                newActivity.endTime = endTime
                newActivity.colour = colours[Int(arc4random_uniform(UInt32(colours.count)))]
                realm.add(newActivity, update: .modified)
            }
        }catch{
            print("Error saving new category-mapping, \(error)")
        }
    }
    
    //    private func saveDailyNeedMap(date: Date){
    //        if(!isNeedSelectionMapEmpty(needSelectionMap: dailyNeedMap)){
    //            if let needJSONData = try? encoder.encode(dailyNeedMap) {
    //                if let jsonString = String(data: needJSONData, encoding: .utf8) {
    //                    do{
    //                        try self.realm.write{
    //                            let newDailyNeed = DailyNeed()
    //                            newDailyNeed.dateCreated = date.dateFormatter(format: "yyyy-MM-dd")
    //                            newDailyNeed.needResult = jsonString
    //                            realm.add(newDailyNeed, update: .modified)
    //                        }
    //                    }catch{
    //                        print("Error saving new category-mapping, \(error)")
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    private func saveDailyActivityMap(date: Date){
        if(!isNeedNumActivityMapEmpty(needNumActivityMap: dailyActivityMap)){
            if let needActivityJSONData = try? encoder.encode(dailyActivityMap){
                if let jsonString = String(data: needActivityJSONData, encoding: .utf8){
                    do{
                        try self.realm.write{
                            let newDailyActivity = DailyActivity()
                            newDailyActivity.dateCreated = date.dateFormatter(format: "yyyy-MM-dd")
                            newDailyActivity.numActivityResult = jsonString
                            realm.add(newDailyActivity, update: .modified)
                        }
                    }catch{
                        print("Error saving new activity-category mapping, \(error)")
                    }
                }
            }
        }
    }
    
    private func saveSelectedNeeds(){
        do{
            try self.realm.write{
                let newActivityNeed = ActivityNeed()
                selectedNeeds = selectedNeeds.trimmingCharacters(in: .whitespacesAndNewlines)
                newActivityNeed.selectedNeeds = selectedNeeds
                newActivityNeed.activityID = activityID!
                realm.add(newActivityNeed, update: .modified)
            }
        }catch{
            print("Error saving new selected needs, \(error)")
        }
    }
    
    private func cleanPyramidMapData(){
        for innerView in backView.subviews as [UIView]{
            if let needButton = innerView as? UIButton {                            needButton.setTitleColor(.white, for: .normal)
            }
        }
    }
    
    private func loadActivityID(activityText: String) -> String?{
        let selectedActivity = realm.objects(Activity.self).filter("activityText = '\(activityText)'")
        if selectedActivity.count>0{
            return selectedActivity[0].activityID
        }
        return nil
    }
    
    private func populateDailyActivityMap(date: Date){
        let decodedNeedActivityData = loadDailyActivityResult(date: date)
        if let safeDecodedNeedActivityData = decodedNeedActivityData{
            for needType in Utils.needTypeList{
                dailyActivityMap[needType] = safeDecodedNeedActivityData[needType]
            }
        }
        print(dailyActivityMap)
    }
    
    private func populateSelectedNeed(activityID: String){
        let selectedActivityNeed = realm.objects(ActivityNeed.self).filter("activityID = '\(activityID)'")
        if selectedActivityNeed.count>0{
            selectedNeeds = selectedActivityNeed[0].selectedNeeds
            let selectedNeedsArray = selectedNeeds.components(separatedBy: " ")
            print(selectedNeedsArray)
            for need in selectedNeedsArray{
                setPyramidMapData(need: need)
            }
        }else{
            selectedNeeds = ""
        }
    }
    
    //    private func populateDailyNeedMap(date: Date){
    //
    //        let decodedDailyNeedData = loadDailyNeed(date: date)
    //
    //        if let safeDecodedDailyNeedData = decodedDailyNeedData{
    //            for needType in Utils.needTypeList{
    //                if safeDecodedDailyNeedData[needType]{
    //                    dailyNeedMap[needType] = true
    //                    setPyramidMapData(need: needType)
    //                }else{
    //                    dailyNeedMap[needType] = false
    //                }
    //            }
    //        }
    //    }
    
    private func setPyramidMapData(need: String){
        for innerView in backView.subviews as [UIView]{
            if let needButton = innerView as? UIButton {
                let buttonLabel = needButton.titleLabel?.text
                if buttonLabel == "personal security" && need == "personal_security"{
                    needButton.setTitleColor(.black, for: .normal)
                }else if buttonLabel == "self-esteem" && need == "self_esteem"{
                    needButton.setTitleColor(.black, for: .normal)
                }else if buttonLabel == "Self Actualization" && need == "self_actualization" {
                    needButton.setTitleColor(.black, for: .normal)
                }else if buttonLabel == need{
                    needButton.setTitleColor(.black, for: .normal)
                }
            }
        }
    }
    
    private func isNeedSelectionMapEmpty(needSelectionMap: [String:Bool]) -> Bool{
        for key in needSelectionMap.keys{
            if (needSelectionMap[key]!){
                return false
            }
        }
        return true
    }
    
    private func isNeedNumActivityMapEmpty(needNumActivityMap: [String:Int]) -> Bool{
        for key in needNumActivityMap.keys{
            if (needNumActivityMap[key] != 0){
                return false
            }
        }
        return true
    }
    
    //MARK: - Swipe Functionality
    @objc func swipedLeft(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            performSegue(withIdentifier: Utils.userInputReportSegue, sender: self)
        }
    }
    
    @objc func swipedRight(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            performSegue(withIdentifier: Utils.userInputCalendarSegue, sender: self)
        }
    }
    
    lazy var leftSwipeGestureRecognizer: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .left
        gesture.addTarget(self, action: #selector(swipedLeft))
        return gesture
    }()
    
    lazy var rightSwipeGestureRecognizer: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .right
        gesture.addTarget(self, action: #selector(swipedRight))
        return gesture
    }()
}


extension UserInputViewController: ActivityTimePickerDelegate {
    
    @objc func showTimePicker() {
        let customAlert = self.storyboard?.instantiateViewController(withIdentifier: "activitytimepicker") as! ActivityTimePicker
        customAlert.providesPresentationContextTransitionStyle = true
        customAlert.definesPresentationContext = true
        customAlert.modalPresentationStyle = .popover
        customAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        customAlert.delegate = self
        self.present(customAlert, animated: true, completion: nil)
    }
    
    func pickerAlertCancel() {}
    
    func pickerAlertSelected(t1: String, t2: String) {
        saveActivity(startTime: t1, endTime: t2)
    }
}
