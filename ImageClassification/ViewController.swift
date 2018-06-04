//
//  ViewController.swift
//  ImageClassification
//
//  Created by Milan on 2018. 06. 04..
//  Copyright © 2018. Milan. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var captionLabel: UILabel!
    var faceBoxView: UIView = UIView()
    let imagePickerController = UIImagePickerController()
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 10
        imageView.layer.borderColor = UIColor.init(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0).cgColor
        imageView.layer.borderWidth = 1.5
        imagePickerController.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Take or pick phot methods
    
    @IBAction func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.cameraDevice = .front
        }
        
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: Classification and recognition methods
    
    private func classifySceneAndDetectFace(from image: UIImage) {
        // 1. Create Vision Core ML request with model
        /* let model = GoogLeNetPlaces()
        guard let visionCoreMLModel = try? VNCoreMLModel(for: model.model) else { return }
        let sceneClassificationRequest = VNCoreMLRequest(model: visionCoreMLModel,
                                                         completionHandler: self.handleSceneClassificationResults) */
        self.faceBoxView.removeFromSuperview()
        
        // 2. Create Vision face detection request
        // - completion handler should take in handleFaceDetectionResults
        /* let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaceDetectionResults) */
        
        // Create request handler
        guard let cgImage = image.cgImage else {
            fatalError("Unable to convert \(image) to CGImage.")
        }
        let cgImageOrientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation)
        DispatchQueue.main.async {
            self.captionLabel.text = "Classifying scene, detecting face..."
        }
        
        // 3. Perform both requests on handler
        // - Ensure perform work is dispatched on appropriate queue (not main queue)
        /* DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([sceneClassificationRequest, faceDetectionRequest])
            } catch {
                print("Error performing scene calssification")
            }
        } */
    }
    
    private func handleSceneClassificationResults(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let classifications = request.results as? [VNClassificationObservation],
                classifications.isEmpty != true else {
                    self.captionLabel.text = "Unable to classify scene.\n\(error!.localizedDescription)"
                    return
            }
            self.updateCaptionLabel(classifications)
        }
    }
    
    // 4. Handle face detection results
    // - Add face box view
    // - Ensure that it is dispatched on the main queue, because we are updating the UI
    private func handleFaceDetectionResults(request: VNRequest, error: Error?) {
        /* guard let observation = request.results?.first as? VNFaceObservation else {
            return
        }
        
        DispatchQueue.main.async {
            self.addFaceBoxView(faceBoundingBox: observation.boundingBox)
        } */
    }
    
    // MARK: Helper methods
    
    private func updateCaptionLabel(_ classifications: [VNClassificationObservation]) {
        let topClassifications = classifications.prefix(5)
        let descriptions = topClassifications.map { classification in
            return String(format: " (%.2f) %@", classification.confidence, classification.identifier)
        }
        self.captionLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
    }
    
    private func convertToCGImageOrientation(from uiImage: UIImage) -> CGImagePropertyOrientation {
        let cgImageOrientation = CGImagePropertyOrientation(rawValue: UInt32(uiImage.imageOrientation.rawValue))!
        return cgImageOrientation
    }
    
    private func addFaceBoxView(faceBoundingBox: CGRect) {
        let faceBoxView = UIView()
        
        let boxViewFrame = transformRectInView(visionRect: faceBoundingBox, view: self.imageView)
        faceBoxView.frame = boxViewFrame
        
        imageView.addSubview(faceBoxView)
        self.faceBoxView = faceBoxView
        styleFaceBoxView(faceBoxView)
    }
    
    private func styleFaceBoxView(_ faceBoxView: UIView) {
        faceBoxView.layer.borderColor = UIColor.init(red: 50.0/255.0, green: 137.0/255.0, blue: 235.0/255.0, alpha: 1.0).cgColor
        faceBoxView.layer.borderWidth = 1.5
        faceBoxView.backgroundColor = UIColor.init(red: 50.0/255.0, green: 137.0/255.0, blue: 235.0/255.0, alpha: 0.2)
    }
    
    private func transformRectInView(visionRect: CGRect , view: UIView) -> CGRect {
        let size = CGSize(width: visionRect.width * view.bounds.width,
                          height: visionRect.height * view.bounds.height)
        let origin = CGPoint(x: visionRect.minX * view.bounds.width,
                             y: (1 - visionRect.minY) * view.bounds.height - size.height)
        return CGRect(origin: origin, size: size)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageSelected = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.imageView.image = imageSelected

            // Kick off Core ML task with image as input
            classifySceneAndDetectFace(from: imageSelected)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
