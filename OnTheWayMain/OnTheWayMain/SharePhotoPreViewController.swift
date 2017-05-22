//
//  SharePhotoPreViewController.swift
//  OnTheWayMain
//
//  Created by nueola on 5/20/17.
//  Copyright © 2017 junwoo. All rights reserved.
//

import UIKit
import Foundation
class SharePhotoPreViewController: UIViewController {
    var capturedImage : UIImage?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var square: UIView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.square.layer.borderWidth = 1.0
        self.square.layer.borderColor = UIColor.white.cgColor
        
        imageView.image = capturedImage
                imageView.addSubview(square)
    }
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    @IBAction func savaImage(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    

}