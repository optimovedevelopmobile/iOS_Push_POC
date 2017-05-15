import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var outputLabel: UILabel!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        var output = "No data stored yet"
        if let storedData = UserDefaults.standard.value(forKey: kStoredDataKey) as? String {
            output = storedData
        }
        outputLabel.text = output
    }
}

