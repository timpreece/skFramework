//
//  DebugInfo.swift
//  skFramework
//
//  Created by Tim Preece on 08/09/2017.
//  Copyright © 2017 Tim Preece. All rights reserved.
//

import SpriteKit
import GameplayKit

//
// helper class that builds a dictionary of debug information and draw it to an SKNode
//
class DebugInfo {
    
    fileprivate var data = [String : Any]()
    fileprivate var layer : SKNode?
    
    func set( layer: SKNode ){
        self.layer = layer
    }
    
    func update( value:Any, forKey:String ){
        data.updateValue(value, forKey: forKey)
    }
    
    func refresh() {
        
        guard let layer = self.layer,
            let view = layer.scene?.view else {
                return
        }
        
        layer.removeAllChildren()
        
        let x = view.bounds.width / 2
        var y = view.bounds.height / 2
        
        for line in data {
            let node = SKLabelNode()
            node.fontSize = 10
            node.fontName = "Courier"
            node.fontColor = SKColor.white
            node.horizontalAlignmentMode = .right
            node.text = "\(line.value)"
            y = y - node.frame.height - 1
            node.position = CGPoint(x: x , y: y)
            layer.addChild( node )
        }
    }
}
