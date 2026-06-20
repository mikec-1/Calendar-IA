import UIKit
var selectedDate = Date()

class WeeklyViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {
    // The following code defines a calendar view with a table and a collection view to display dates.

    // Outlets for the month label, table view, and collection view are defined.
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // An edit button is also defined as an outlet.
    @IBOutlet weak var editButton: UIBarButtonItem!
    //@IBOutlet weak var deleteButton: UIBarButtonItem!

    // An array of dates is defined to keep track of the total squares in the calendar view.
    var totalSquares = [Date]()

    // The viewDidLoad method sets the delegate and data source for the table view and sets the cells view and week view.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setCellsView()
        setWeekView()
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    // The setCellsView method sets the item size for the collection view's flow layout.
    // It calculates the width and height of each cell based on the collection view's frame size.
    func setCellsView() {
        let width = (collectionView.frame.size.width - 2) / 8 //dont change
        let height = (collectionView.frame.size.height - 2) //remove multiplication and division, larger minus makes space larger
    
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    // The setWeekView method updates the month label and reloads both the table view and collection view.
    // It first removes all the dates in the totalSquares array and then appends new dates starting from the current Sunday.
    func setWeekView() {
        totalSquares.removeAll()
        
        var current = CalendarHelper().sundayForDate(date: selectedDate)
        let nextSunday = CalendarHelper().addDays(date: current, days: 7)
        
        while(current < nextSunday) {
            totalSquares.append(current)
            current = CalendarHelper().addDays(date: current, days: 1)
        }
        
        monthLabel.text = CalendarHelper().monthString(date: selectedDate) + " " + CalendarHelper().yearString(date: selectedDate)
        collectionView.reloadData()
        tableView.reloadData()
    }
    // The collectionView:cellForItemAt method sets the content of each cell in the collection view.
    // It sets the day of the month for each cell and changes the background color of the selected date.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarCell
        
        let date = totalSquares[indexPath.item]
        cell.dayOfMonth.text = String(CalendarHelper().daysOfMonth(date: date))
        
        if(date == selectedDate) {
            cell.backgroundColor = UIColor.systemGreen
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    // called when an item in the collection view is selected. sets the "selectedDate" to the selected item in "totalSquares", then reloads both the collection view and table view data.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDate = totalSquares[indexPath.item]
        collectionView.reloadData()
        tableView.reloadData()
    }
    
    // function returns the number of items in the collection view, which is determined by the count of elements in the "totalSquares" array.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalSquares.count
    }
    
    //function is the action for the "previousWeek" button.
    @IBAction func previousWeek(_ sender: Any) {
        selectedDate = CalendarHelper().addDays(date: selectedDate, days: -7)
        setWeekView()
    }
    //function is the action for the "nextWeek" button.
    @IBAction func nextWeek(_ sender: Any) {
        selectedDate = CalendarHelper().addDays(date: selectedDate, days: 7)
        setWeekView()
    }
    
    @IBAction func editButtonTapped(sender: UIButton)
    {
        tableView.setEditing(!tableView.isEditing, animated: true)
        
        sender.setTitle(tableView.isEditing ? "Done" : "Edit", for: [])
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row % 3 == 0 {
            return .delete
        }
        else if indexPath.row % 3 == 1 {
            return .insert
        }

        else {
            return .none
        }
   }
    
//    private func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//            if editingStyle == .delete {
//                // Delete the row from the data source
//                print("delete button clicked at \(indexPath.section)\\\(indexPath.row)")
//                tableView.deleteRows(at: [indexPath], with: .none)
//            } else if editingStyle == .insert {
//                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//                print("insert button clicked at \(indexPath.section)\\\(indexPath.row)")
//            }
//    }
    
    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print("commitEditingStyle called at \(indexPath)")
        if editingStyle == .delete {
            // Delete the row from the data source
            //tableView.deleteRows(at: [indexPath], with: .none)
            print("delete button clicked at \(indexPath.section)\\\(indexPath.row)")
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("insert button clicked at \(indexPath.section)\\\(indexPath.row)")
        }
        
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    var allowsMultipleSelection: Bool { 
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CalendarViewModel.shared.events(for: selectedDate).count
    }
    
    //returns a cell for the specified index path in the table view. dequeues a reusable "EventCell", sets its text to the name and time of the event for the "selectedDate", and returns the cell.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID") as! EventCell
        let event = CalendarViewModel.shared.events(for: selectedDate)[indexPath.row]
        cell.eventLabel.text = event.name + " at " + CalendarHelper().timeString(date: event.date)
        return cell
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
}

