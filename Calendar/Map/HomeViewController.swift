import UIKit

class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let labelRect = CGRect(x: 30, y: 100, width: 500, height: 500)
        
        let label = UILabel(frame: labelRect)
        label.numberOfLines = 5
//        label.text = "Welcome. This is a Calendar based Organizer, designed specifically with Film in mind. This application allows users to view the Calendar in a Monthly, Weekly, or Daily View. When adding a new Event, users are able to select options such as filming location, number of shots and cast members. Everything can be found under the 'Calendar' item in the Taskbar. The Settings allow users to toggle the Dark Mode Theme."
        
        view.addSubview(label)
        
    }
}
