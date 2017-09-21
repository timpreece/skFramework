//
//  GameScene.swift
//  skFramework
//
//  Created by Tim Preece on 08/09/2017.
//  Copyright © 2017 Tim Preece. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
  
  // SKNode layers
  let root = SKNode() // has children that respond to scaling e.g. map, game textures
  let cam = SKCameraNode() // camera
  let overlay = SKNode() // has children that don't respond to scaling e.g. icons, debug text, HUD
  
  // debug text overlay
  private let debugData = DebugInfo()
  
  // gesture recognizers
  private let pinchRec = UIPinchGestureRecognizer()
  private let tapRec = UITapGestureRecognizer()
  private let panRec = UIPanGestureRecognizer()
  
  // camera scale limits
  private var maxScale = CGFloat(2.0) // in
  private var minScale = CGFloat(0.4) // out
  
  //
  // MARK: Initialise SKScene
  //
  override func didMove(to view: SKView) {
    
    self.scaleMode = .resizeFill
    self.backgroundColor = .black
    
    // initialise SKNodes
    
    // rootLayer
    root.zPosition = 0
    self.addChild(root)
    
    // cameraLayer
    cam.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
    cam.zPosition = 999
    cam.setScale(1.0)
    self.addChild(cam)
    self.camera = cam
    
    // overlay
    overlay.zPosition = 1000
    cam.addChild(overlay)
    
    // build additional layers
    addContentToRoot()
    
    addOverlays()
    
    // add gesture recognisers
    pinchRec.addTarget(self, action: #selector(GameScene.pinch))
    self.view!.addGestureRecognizer(pinchRec);
    
    tapRec.addTarget(self, action: #selector(GameScene.tap))
    self.view!.addGestureRecognizer(tapRec);
    
    panRec.addTarget(self, action: #selector(GameScene.pan))
    self.view!.addGestureRecognizer(panRec);
  }
  
  // Root layer and children will zoom
  fileprivate func addContentToRoot() {
    
    // map texture
    let map = SKNode()
    map.zPosition = 10
    map.name = "map"
    // node = self.convert(CGPoint.zero, to: mapLayer)
    root.addChild(map)
    
    // additional map sprite textures
    let mapTextures = SKNode()
    mapTextures.zPosition = 100
    mapTextures.name = "mapTextures"
    root.addChild(mapTextures)
    
    // debug
    addSprites()
  }
  
  // Overlay layer and children will not zoom
  fileprivate func addOverlays() {
    
    // icons
    let icons = SKNode()
    icons.zPosition = 1001
    icons.name = "icons"
    overlay.addChild(icons)
    
    // debug output
    let debug = SKNode()
    debug.zPosition = 9999
    debug.name = "debug"
    overlay.addChild(debug)
    
    // draw debug data on debugLayer node
    debugData.set(layer: debug)
    
    // debug
    addIcons()
  }
  
  // handle zoom
  override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    
    updateZoomLimits()
    
    updateCameraConstraints()
  }
  
  //
  fileprivate func updateZoomLimits() {
    
    let boardContentRect = root.calculateAccumulatedFrame()
    maxScale = min( CGFloat( boardContentRect.width / self.size.width ), CGFloat( boardContentRect.height / self.size.height) )
  }
  
  // constrain camera movement to edge of GameScene
  fileprivate func updateCameraConstraints() {
    
    let cam = self.cam
    
    // get maximum size of map layer (centred on camera origin in middle of scene)
    let boardContentRect = root.calculateAccumulatedFrame()
    
    // get width and height of current view
    let scaledRect = CGSize(width: self.size.width * cam.xScale, height: self.size.height * cam.yScale)
    
    let xInset = min(( scaledRect.width / 2) - 20.0, boardContentRect.width / 2)
    let yInset = min(( scaledRect.height / 2) - 20.0, boardContentRect.height / 2)
    
    // create inner rectangle
    let insetContentRect = boardContentRect.insetBy(dx: xInset, dy: yInset )
    
    // and get x,y min and max based on the inner rectange
    let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
    let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
    
    // create an position x,y constraint over this range
    let borderConstraint = SKConstraint.positionX(xRange, y: yRange)
    borderConstraint.referenceNode = root
    
    // apply constraint to camera Node
    cam.constraints = [borderConstraint]
  }
  
  //
  // MARK: Gesture recognisers
  //
  @objc func pan(_ sender: UIPanGestureRecognizer){
    
    let translation = sender.translation(in: self.view)
    
    // flip translation in x-axis for camera
    let cameraDisplacement = CGVector(dx: -1.0 * translation.x * cam.xScale, dy: translation.y * cam.yScale)
    let action = SKAction.move(by: cameraDisplacement, duration: 0)
    cam.run(action)
    
    // reset translation
    sender.setTranslation(CGPoint.zero, in: self.view)
    
    // debug
    debugData.update(value: "pan", forKey: "gesture")
    debugData.refresh()
  }
  
  @objc func tap(_ sender: UITapGestureRecognizer){
    
    if sender.state == .ended {
      
      // convert touch location to point in scene
      let locInView = sender.location(ofTouch: 0, in: self.view!)
      let locInScene = self.convertPoint(fromView: locInView)
      
      // move camera to touch point
      let cameraDisplacement = CGVector(dx: locInScene.x - cam.position.x, dy: locInScene.y - cam.position.y)
      let action = SKAction.move(by: cameraDisplacement, duration: 0.5)
      cam.run(action)
      
      // debug
      debugData.update(value: "tap", forKey: "gesture")
      debugData.refresh()
    }
  }
  
  @objc func pinch(_ sender: UIPinchGestureRecognizer){
    
    guard sender.numberOfTouches > 1 else {
      return
    }
    
    // get anchor point
    let pointInView = sender.location(in: self.view)
    let point = self.convertPoint(fromView: pointInView)
    
    // rescale within constraints
    var newScale = cam.xScale * 1.0 / sender.scale
    newScale = newScale > maxScale ? maxScale : newScale
    newScale = newScale < minScale ? minScale : newScale
    
    // create SKAction and update Camera Constraints when SKAction is complete
    let action = SKAction.scale(to: newScale, duration: 0)
    cam.run(action)
    
    // move camera to reflect anchor point
    let pointAfterScale = self.convertPoint(fromView: pointInView)
    let delta = CGPoint(x: point.x - pointAfterScale.x, y: point.y - pointAfterScale.y)
    let newPosition = CGPoint(x: cam.position.x + delta.x, y: cam.position.y + delta.y)
    
    cam.position = newPosition
    
    // scale has changed to update CameraPosition constraints
    self.updateCameraConstraints()
    
    // reset scale
    sender.scale = 1.0
    
    // debug
    debugData.update(value: "pinch", forKey: "gesture")
    debugData.update(value: newScale, forKey: "scale")
    debugData.refresh()
  }
  
  //
  // MARK: didApplyConstraints
  //
  override func didApplyConstraints() {
    // update icon layer now scene movement/scaling is complete
    addIcons()
  }
  
  //
  // MARK: Update method called before frame is rendered
  //
  override func update(_ currentTime: TimeInterval) {
  }
  
  //
  // MARK: Debug methods that draw icons
  //
  fileprivate func addSprites(){
    
    guard let mapTextures = root.childNode(withName: "mapTextures") else {
      print("Error: Unable to add sprites to SKNode 'mapTextures'")
      return
    }
    
    let texture = SKTexture(imageNamed: "gSquare")
    
    mapTextures.removeAllChildren()
    
    let coords = [ [0,0], [1024,1024], [0,2048], [2048,2048], [2048,0], [512,512], [512,1536], [1536,1536], [1536,512] ]
    
    for xy in coords {
      
      let node = SKSpriteNode(texture: texture)
      node.position = self.convert(CGPoint(x:xy[0], y:xy[1]), to: mapTextures)
      mapTextures.addChild(node)
    }
  }
  
  fileprivate func addIcons(){
    
    guard let icons = overlay.childNode(withName: "icons") else {
      print("Error: Unable to add icons to SKNode 'icons'")
      return
    }
    
    let texture = SKTexture(imageNamed: "yCircle")
    
    icons.removeAllChildren()
    
    let coords = [ [0,0], [1024,1024], [0,2048], [2048,2048], [2048,0], [512,512], [512,1536], [1536,1536], [1536,512] ]
    
    for xy in coords {
      
      let node = SKSpriteNode(texture: texture)
      node.position = self.convert(CGPoint(x:xy[0], y:xy[1]), to: icons)
      icons.addChild(node)
    }
  }
}

