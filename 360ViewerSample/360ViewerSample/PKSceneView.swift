//
//  PKSceneView.swift
//  SceneViewSubClass
//
//  Created by Jarvis on 19/09/19.
//  Copyright © 2019 Jarvis. All rights reserved.
//

import SceneKit
import AudioToolbox

protocol PKSceneViewDelegate : class {
    func didLongPressScene(hitTestResult: SCNHitTestResult)
    func didTapScene(hitTestResult : SCNHitTestResult)
}

class PKSceneView: SCNView {
    var startScale = 0.0
    var prevLocation = CGPoint.zero
    @objc var panSpeed = CGPoint(x: 0.005, y: 0.005)
    var prevBounds = CGRect.zero
    
    var sphereNode : SCNNode!
    
    let apartmentScene = SCNScene()
    
    lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        let camera = SCNCamera()
        node.camera = camera
        return node
    }()
    
    var xFov: CGFloat {
        return yFov * (self.bounds.width) / (self.bounds.height)
    }
    
    var yFov: CGFloat {
        get {
            if #available(iOS 11.0, *) {
                return cameraNode.camera?.fieldOfView ?? 0
            } else {
                return CGFloat(cameraNode.camera?.yFov ?? 0)
            }
        }
        set {
            if #available(iOS 11.0, *) {
                cameraNode.camera?.fieldOfView = newValue
            } else {
                cameraNode.camera?.yFov = Double(newValue)
            }
        }
    }

    var material : SCNMaterial!
    
    weak var sceneDelegate : PKSceneViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        
        self.scene = apartmentScene
        
        self.scene?.rootNode.addChildNode(cameraNode)
        yFov = 80
        
        self.backgroundColor = UIColor.black
        
        setupGestures()
        
        material = getMaterial()
        
        let sphere = SCNSphere(radius: 8)
        sphereNode = SCNNode()
        sphere.segmentCount = 300
        sphere.firstMaterial = material
        sphereNode.geometry = sphere
        
        self.scene?.rootNode.addChildNode(sphereNode)
    }

}

extension PKSceneView {
    func updateMaterialTexture(image: UIImage?) {
        DispatchQueue.main.async {
            self.material.diffuse.contents = image
        }
    }
    
    func getMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .linear
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        material.cullMode = .front
        material.isDoubleSided = false
        return material
    }
}

extension PKSceneView {
    func setupGestures() {
        let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
        self.addGestureRecognizer(panGestureRec)
        
        let pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRec:)))
        self.addGestureRecognizer(pinchRec)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(rec:)))
        longPress.minimumPressDuration = 0.4
        self.addGestureRecognizer(longPress)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handlePan(panRec: UIPanGestureRecognizer) {
        if panRec.state == .began {
            prevLocation = CGPoint.zero
        } else if panRec.state == .changed {
            let modifiedPanSpeed = panSpeed
            let location = panRec.translation(in: self)
            let orientation = cameraNode.eulerAngles
            var newOrientation = SCNVector3Make(orientation.x + Float(location.y - prevLocation.y) * Float(modifiedPanSpeed.y),
                                                orientation.y + Float(location.x - prevLocation.x) * Float(modifiedPanSpeed.x),
                                                orientation.z)
            
            newOrientation.x = max(min(newOrientation.x, 1.1), -1.1)
            
            cameraNode.eulerAngles = newOrientation
            prevLocation = location
        }
    }
    
    @objc func handlePinch(pinchRec: UIPinchGestureRecognizer) {
        if pinchRec.numberOfTouches != 2 {
            return
        }
        
        let zoom = Double(pinchRec.scale)
        switch pinchRec.state {
        case .began:
            startScale = Double(cameraNode.camera!.fieldOfView)
        case .changed:
            let fov = startScale / zoom
            if fov > 20 && fov < 80 {
                cameraNode.camera!.fieldOfView = CGFloat(fov)
            }
        default:
            break
        }
    }
    
    @objc func handleLongPress(rec: UILongPressGestureRecognizer) {
        if rec.state == .began {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            
            let location: CGPoint = rec.location(in: self)
            let hits = self.hitTest(location, options: nil)
            
            if !hits.isEmpty {
                let result: SCNHitTestResult = hits[0]
                sceneDelegate?.didLongPressScene(hitTestResult: result)
            }

        }
    }
    
    @objc func handleTap(rec: UITapGestureRecognizer){
        if rec.state == .ended {
            if rec.state == .ended {
                let location: CGPoint = rec.location(in: self)
                let hits = self.hitTest(location, options: nil)
                
                if !hits.isEmpty {
                    let result: SCNHitTestResult = hits[0]
                    sceneDelegate?.didTapScene(hitTestResult: result)
                }
            }
        }
    }
}
