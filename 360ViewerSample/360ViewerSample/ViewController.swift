//
//  ViewController.swift
//  360ViewerSample
//
//  Created by Jarvis on 28/11/19.
//  Copyright © 2019 Jarvis. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: PKSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.sceneDelegate = self
        
        let image = UIImage(named: "sample.jpeg", in: nil, compatibleWith: nil)
        
        DispatchQueue.main.async {
            self.sceneView.updateMaterialTexture(image: image )
        }
    }


}

extension ViewController : PKSceneViewDelegate {
    
    func didLongPressScene(hitTestResult: SCNHitTestResult) {
        // Handle Long press gesture
    }
    
    func didTapScene(hitTestResult: SCNHitTestResult) {
        // Handle tap gesture
    }
}
