//
//  ViewController.swift
//  SpotTheScientist
//
//  Created by Koty Stannard on 4/28/19.
//  Copyright © 2019 Koty Stannard. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    //dictionary of scientists with scientists as key
    var scientists = [String: Scientist]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Scientists", bundle: nil) else {
            fatalError("Couldn't load tracking images")
        }
        
        configuration.trackingImages = trackingImages

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //Basically attaches a node to an anchor
    //If the anchor moves around the screen, the node will move with it
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        guard let name = imageAnchor.referenceImage.name else { return nil }
        guard let scientist = scientists[name] else { return nil }
        
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = UIColor.clear
        
        let planeNode = SCNNode(geometry: plane)
        
        //Keep horizontal axis fixed as the node moves around
        planeNode.eulerAngles.x = -.pi / 2
        
        let node = SCNNode()
        node.addChildNode(planeNode)
        
        //space between picture and title - in meters
        let spacing: Float = 0.005
        
        let titleNode = textNode(scientist.name, font: UIFont.boldSystemFont(ofSize: 10))
        titleNode.pivotOnTopLeft()  //position on top left edge of the view
        
        titleNode.position.x += Float(plane.width / 2) + spacing
        titleNode.position.y += Float(plane.height / 2)
        planeNode.addChildNode(titleNode)
        
        let bioNode = textNode(scientist.bio, font: UIFont.systemFont(ofSize: 4), maxWidth: 100)
        bioNode.pivotOnTopLeft()
        
        //position bio coordinates and place below titleNode
        bioNode.position.x += Float(plane.width / 2) + spacing
        bioNode.position.y = titleNode.position.y - titleNode.height - spacing
        planeNode.addChildNode(bioNode)
        
        let flag = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.width / 8 * 5)
        flag.firstMaterial?.diffuse.contents = UIImage(named: scientist.country)
        
        //place flag in scene
        let flagNode = SCNNode(geometry: flag)
        flagNode.pivotOnTopCenter()
        
        flagNode.position.y -= Float(plane.height / 2) + spacing
        planeNode.addChildNode(flagNode)
        
        return node
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "scientists", withExtension: "json") else {
            fatalError("Unable to find JSON in bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to load JSON")
        }
        
        let decoder = JSONDecoder()
        guard let loadedScientists = try? decoder.decode([String: Scientist].self, from: data) else {
            fatalError("Unable to parse JSON")
        }
        
        scientists = loadedScientists
    }
    
    //Add scientist text to the screen
    func textNode(_ str: String, font: UIFont, maxWidth: Int? = nil) -> SCNNode {
        //what string and how deep the text goes - here it's flat
        let text = SCNText(string: str, extrusionDepth: 0)
        
        //smooth out text
        text.flatness = 0.1
        text.font = font
        
        if let maxWidth = maxWidth {
            text.containerFrame = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 500))
            text.isWrapped = true
        }
        
        //create text node and scale it down
        let textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(0.002, 0.002, 0.002)
        
        return textNode
    }
}

//extension to help with positioning things on screen
extension SCNNode {
    var width: Float {
        //returns real world width of position
        return (boundingBox.max.x - boundingBox.min.x) * scale.x
    }
    
    var height: Float {
        return (boundingBox.max.y - boundingBox.min.y) * scale.y
    }
    
    func pivotOnTopLeft() {
        let (min, max) = boundingBox    //decompose bounding box into 2 values
        pivot = SCNMatrix4MakeTranslation(min.x, (max.y - min.y) + min.y, 0)
    }
    
    func pivotOnTopCenter() {
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2 + min.x, (max.y - min.y) + min.y, 0)
    }
}
