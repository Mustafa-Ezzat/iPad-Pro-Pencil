//
//  Colors.swift
//  Scribble
//
//  Created by Mustafa Ezzat on 2/24/17.
//  Copyright © 2017 Caroline Begbie. All rights reserved.
//


import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var canvasView: CanvasView!

  override func viewDidLoad() {
    super.viewDidLoad()
    canvasView.clearCanvas(animated:false)
  }
  
  // Shake to clear screen
  override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
    canvasView.clearCanvas(animated: true)
  }
  
  @IBAction func btnCoalesced(_ button:UIButton) {
    canvasView.isCoalesced = !canvasView.isCoalesced
    if (canvasView.isCoalesced) {
      button.setTitle("Coalesced ON", for: UIControlState())
    } else {
      button.setTitle("Coalesced OFF", for: UIControlState())
    }
  }

  @IBAction func btnPredicted(_ button:UIButton) {
    canvasView.isPredicted = !canvasView.isPredicted
    if (canvasView.isPredicted) {
      button.setTitle("Predicted ON", for: UIControlState())
    } else {
      button.setTitle("Predicted OFF", for: UIControlState())
    }
  }
  
  @IBAction func btnShowPredicted(_ button:UIButton) {
    canvasView.isShowPredicted = !canvasView.isShowPredicted
    if (canvasView.isShowPredicted) {
      button.setTitle("Show Predicted ON", for: UIControlState())
    } else {
      button.setTitle("Show Predicted OFF", for: UIControlState())
    }

  }
  
    @IBAction func drawAction(_ sender: AnyObject) {
        canvasView.isDraw = true
        canvasView.isErase = false

    }
  
    @IBAction func eraseAction(_ sender: AnyObject) {
        canvasView.isDraw = false
        canvasView.isErase = true

    }
}



