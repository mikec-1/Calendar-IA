import UIKit

// Class ViewController is a subclass of UIViewController and conforms to the UICollectionViewDelegate, UICollectionViewDataSource, and UITableViewDelegate protocols
class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate {
    
    // monthLabel and collectionView are connected to the corresponding UI elements in the storyboard
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // The ViewModel handles the date maths and generates the list of days.
    private let viewModel = CalendarViewModel.shared
    
    // viewDidLoad is called when the view has loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize the view setup
        setCellsView()
        
        // Listen for async updates (like weather data)
        viewModel.onUpdateUI = { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
        
        // Populate initial data
        viewModel.updateDaysInMonth()
        updateMonthLabel()
    }

    // setCellsView sets the size of the cells in the collectionView
    func setCellsView() {
        // width is calculated as the width of the collectionView minus 5 divided by 7.5
        let width = (collectionView.frame.size.width - 5) / 7.5 
        // height is calculated as the height of the collectionView minus 5 divided by 7.5
        let height = (collectionView.frame.size.height - 5) / 7.5 
    
        // the flowLayout is cast as a UICollectionViewFlowLayout
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        // the item size of the flowLayout is set to the calculated width and height
        flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    // updateMonthLabel reflects the currently selected month in the UI
    func updateMonthLabel() {
        monthLabel.text = viewModel.monthYearString()
        collectionView.reloadData()
    }
    
    // Define the function to create the cells in the collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarCell
        
        // Retrieve the calendar day for the current cell from ViewModel
        let calendarDay = viewModel.totalSquares[indexPath.item]
        
        // Set the day of the month for the cell
        cell.dayOfMonth.text = calendarDay.day
        
        // Set the text color of the day of the month based on whether it is in the current, previous, or next month
        if(calendarDay.month == .current) {
            cell.dayOfMonth.textColor = .label
        } else {
            cell.dayOfMonth.textColor = .secondaryLabel
        }
        
        // Show or hide the event indicator dot
        cell.eventIndicator.isHidden = !calendarDay.hasEvents
        
        // Setup Weather icon (if any)
        if let iconName = calendarDay.weatherIconName {
            cell.weatherIconView.image = UIImage(systemName: iconName)
            cell.weatherIconView.isHidden = false
        } else {
            cell.weatherIconView.image = nil
            cell.weatherIconView.isHidden = true
        }
        
        return cell
    }

    // Define the function to determine the number of cells in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.totalSquares.count
    }
    
    // Handle tap on a specific calendar day
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDay = viewModel.totalSquares[indexPath.item]
        
        // Pass the actual date to the ViewModel so the rest of the app knows what's selected
        viewModel.selectedDate = selectedDay.date
        
        // Present the Daily Agenda view as a bottom sheet
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let dailyVC = storyboard.instantiateViewController(withIdentifier: "DailyViewController") as? DailyViewController {
            
            // Pass the selected date to the DailyViewController
            selectedDate = viewModel.selectedDate // Update global variable used by DailyViewController
            
            // Configure bottom sheet presentation
            if let sheet = dailyVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()] // Allow half and full screen
                sheet.prefersGrabberVisible = true
            }
            
            self.present(dailyVC, animated: true)
        }
    }

    // Action to move to the previous month
    @IBAction func previousMonth(_ sender: Any) {
        viewModel.previousMonth()
        updateMonthLabel()
    }

    // Action to move to the next month
    @IBAction func nextMonth(_ sender: Any) {
        viewModel.nextMonth()
        updateMonthLabel()
    }

    // Override function to disable autorotation
    override open var shouldAutorotate: Bool {
        return false
    }

    // Function to set the month view when the view appears
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure data is up-to-date
        viewModel.updateDaysInMonth()
        updateMonthLabel()
    }
}

