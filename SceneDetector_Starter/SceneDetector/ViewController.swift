

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

  // MARK: - IBOutlets
  @IBOutlet weak var scene: UIImageView!
  @IBOutlet weak var answerLabel: UILabel!

  // MARK: - Properties
  let vowels: [Character] = ["a", "e", "i", "o", "u"]

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    guard let image = UIImage(named: "train_night") else {
      fatalError("no starting image")
    }

    scene.image = image
    
    guard let ciImage = CIImage(image: image) else {
      fatalError("couldn't convert UIImage to CIImage")
    }
    
    detectScene(image: ciImage)
  }
}

// MARK: - IBActions
extension ViewController {

  @IBAction func pickImage(_ sender: Any) {
    let pickerController = UIImagePickerController()
    pickerController.delegate = self
    pickerController.sourceType = .savedPhotosAlbum
    present(pickerController, animated: true)
  }
}

// Mark - Methods
extension ViewController {
  
  func detectScene(image: CIImage) {
    answerLabel.text = "detecting scene..."
    
    guard let model = try? VNCoreMLModel(for: MobileNet().model) else {
        fatalError("can't load Places ML model")
      }
    
    // Create a Vision request with completion handler
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      guard let results = request.results as? [VNClassificationObservation],
        let topResult = results.first else {
          fatalError("unexpected result type from VNCoreMLRequest")
      }
      
      // Update UI on main queue
      let article = (self?.vowels.contains(topResult.identifier.first!))! ? "an" : "a"
      DispatchQueue.main.async { [weak self] in
        self?.answerLabel.text = "\(Int(topResult.confidence * 100))% it's \(article) \(topResult.identifier)"
      }
    }
    
    // Run the Core ML GoogLeNetPlaces classifier on global dispatch queue
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        print(error)
      }
    }
    
  }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    dismiss(animated: true)

    guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
      fatalError("couldn't load image from Photos")
    }

    scene.image = image
    
    guard let ciImage = CIImage(image: image) else {
      fatalError("couldn't convert UIImage to CIImage")
    }
    
    detectScene(image: ciImage)
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}
