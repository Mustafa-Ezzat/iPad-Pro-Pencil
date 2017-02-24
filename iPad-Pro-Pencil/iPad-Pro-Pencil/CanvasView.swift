//
//  Colors.swift
//  Scribble
//
//  Created by Mustafa Ezzat on 2/24/17.
//  Copyright © 2017 Caroline Begbie. All rights reserved.
//

import UIKit

let π = CGFloat(M_PI)

class CanvasView: UIImageView {
  
  var isCoalesced = false
  var isPredicted = false
  var isShowPredicted = false
  
    var isDraw = true
    var isErase = false
    
  
  // Parameters
  fileprivate let DefaultLineWidth:CGFloat = 6
  fileprivate let ForceSensitivity:CGFloat = 4.0
  fileprivate let TiltThreshold = π/6  // 30º
  fileprivate let MinLineWidth:CGFloat = 5
  
  fileprivate var drawingImage: UIImage?
  
  fileprivate var pencilTexture: UIColor = UIColor(patternImage: UIImage(named: PencilTexture)!)
  
  fileprivate var eraserColor: UIColor {
    /*if let backgroundColor = self.backgroundColor {
      return backgroundColor
    }*/
    return UIColor.clear
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    
    // Draw previous image into context
    drawingImage?.draw(in: bounds)
    
    // 1
    var touches = [UITouch]()
    
    // Coalesce Touches
    // 2
    if let coalescedTouches = event?.coalescedTouches(for: touch) , isCoalesced {
      touches = coalescedTouches
    } else {
      touches.append(touch)
    }
    
    // 4
    for touch in touches {
      drawStroke(context, touch: touch, isPredictedTouch: false)
    }
    
    // 1
    drawingImage = UIGraphicsGetImageFromCurrentImageContext()
    // 2
    if let predictedTouches = event?.predictedTouches(for: touch) , isPredicted {
      for touch in predictedTouches {
        drawStroke(context, touch: touch, isPredictedTouch: true)
      }
    }
    
    if isShowPredicted {
      drawingImage = UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Update image
    self.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
  }
  
  override func touchesEnded(_ touches: Set<UITouch>,
    with event: UIEvent?) {
      self.image = drawingImage
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>,
    with event: UIEvent?) {
      self.image = drawingImage
  }
    func getPixelColorAtPoint(_ point:CGPoint) -> UIColor{
        
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context?.translateBy(x: -point.x, y: -point.y)
        self.layer.render(in: context!)
        let color:UIColor = UIColor(red: CGFloat(pixel[0])/255.0, green: CGFloat(pixel[1])/255.0, blue: CGFloat(pixel[2])/255.0, alpha: CGFloat(pixel[3])/255.0)
        
        pixel.deallocate(capacity: 4)
        return color
    }

  fileprivate func drawStroke(_ context: CGContext?, touch: UITouch, isPredictedTouch:Bool) {
    let previousLocation = touch.previousLocation(in: self)
    let location = touch.location(in: self)
    
    var lineWidth:CGFloat
    // Calculate line width for drawing stroke
    if touch.altitudeAngle < TiltThreshold {
        lineWidth = lineWidthForShading(context, touch: touch)
    } else {
        lineWidth = lineWidthForDrawing(context, touch: touch)
    }
    
    if isDraw == true {
      
      // Set color
      if isShowPredicted && isPredictedTouch {
        UIColor.blue.setStroke()
      } else {
        pencilTexture.setStroke()
        
        context?.setBlendMode(.normal)
      }
    } else {
      // Erase with finger
        //NSLog("eraser.....")
        //if(touch.type != .Stylus){
          //  lineWidth = touch.majorRadius / 2
       // }
        pencilTexture.setStroke()
        
        context?.setBlendMode(.clear)
      //eraserColor.setStroke()
    }
    
    // Configure line
    context?.setLineWidth(lineWidth)
    context?.setLineCap(.round)

    
    // Set up the points
    context?.move(to: CGPoint(x: previousLocation.x, y: previousLocation.y))
    context?.addLine(to: CGPoint(x: location.x, y: location.y))
    // Draw the stroke
    context?.strokePath()
    
  }
  
  fileprivate func lineWidthForShading(_ context: CGContext?, touch: UITouch) -> CGFloat {
    
    // 1
    let previousLocation = touch.previousLocation(in: self)
    let location = touch.location(in: self)
    
    // 2 - vector1 is the pencil direction
    let vector1 = touch.azimuthUnitVector(in: self)
    
    // 3 - vector2 is the stroke direction
    let vector2 = CGPoint(x: location.x - previousLocation.x,
      y: location.y - previousLocation.y)
    
    // 4 - Angle difference between the two vectors
    var angle = abs(atan2(vector2.y, vector2.x)
      - atan2(vector1.dy, vector1.dx))
    
    // 5
    if angle > π {
      angle = 2 * π - angle
    }
    if angle > π / 2 {
      angle = π - angle
    }
    
    // 6
    let minAngle:CGFloat = 0
    let maxAngle:CGFloat = π / 2
    let normalizedAngle = (angle - minAngle) / (maxAngle - minAngle)
    
    // 7
    let maxLineWidth:CGFloat = 60
    var lineWidth:CGFloat
    lineWidth = maxLineWidth * normalizedAngle
    
    // 1 - modify lineWidth by altitude (tilt of the Pencil)
    // 0.25 radians means widest stroke and TiltThreshold is where shading narrows to line.
    
    let minAltitudeAngle:CGFloat = 0.25
    let maxAltitudeAngle:CGFloat = TiltThreshold
    
    // 2
    let altitudeAngle = touch.altitudeAngle < minAltitudeAngle
      ? minAltitudeAngle : touch.altitudeAngle
    
    // 3 - normalize between 0 and 1
    let normalizedAltitude = 1 - ((altitudeAngle - minAltitudeAngle)
      / (maxAltitudeAngle - minAltitudeAngle))
    // 4
    lineWidth = lineWidth * normalizedAltitude + MinLineWidth
    
    // Set alpha of shading using force
    let minForce:CGFloat = 0.0
    let maxForce:CGFloat = 5
    
    // Normalize between 0 and 1
    let normalizedAlpha = (touch.force - minForce) / (maxForce - minForce)
    
    context?.setAlpha(normalizedAlpha)
    
    return lineWidth
  }
  
  
  fileprivate func lineWidthForDrawing(_ context: CGContext?, touch: UITouch) -> CGFloat {

    var lineWidth:CGFloat
    lineWidth = DefaultLineWidth
    
    if touch.force > 0 {  // If finger, touch.force = 0
      lineWidth = touch.force * ForceSensitivity
    }
    
    return lineWidth
  }
  
  func clearCanvas(animated: Bool) {
    if animated {
      UIView.animate(withDuration: 0.5, animations: {
        self.alpha = 0
        }, completion: { finished in
          self.alpha = 1
          self.image = nil
          self.drawingImage = nil
      })
    } else {
      self.image = nil
      self.drawingImage = nil
    }
  }
}
