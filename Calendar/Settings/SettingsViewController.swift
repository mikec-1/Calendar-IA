import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var modeSwitch: UISwitch!
    
    // Create a segmented control programmatically to give the user 3 options
    private let themeSegmentedControl: UISegmentedControl = {
        let items = ["System", "Light", "Dark"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the old switch from the storyboard
        modeSwitch.isHidden = true
        
        // Setup the new Segmented Control
        view.addSubview(themeSegmentedControl)
        
        // Position it where the old switch sat
        NSLayoutConstraint.activate([
            themeSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            themeSegmentedControl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            themeSegmentedControl.widthAnchor.constraint(equalToConstant: 250)
        ])
        
        // Load saved preference or default to System (0)
        let savedTheme = UserDefaults.standard.integer(forKey: "appTheme")
        themeSegmentedControl.selectedSegmentIndex = savedTheme
        
        // Add action target
        themeSegmentedControl.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
    }
    
    @objc private func themeChanged(_ sender: UISegmentedControl) {
        guard let window = UIApplication.shared.windows.first else { return }
        
        // Save user preference
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "appTheme")
        
        switch sender.selectedSegmentIndex {
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            // System Default (0)
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    // We keep this to prevent storyboard crashes if it's still linked
    @IBAction func valueChanged(_ sender: Any) {}
}
