//
//  TestController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Yujie Tao on 11/13/21.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import Foundation

let motionManager = CMMotionManager()

self.motionManager.accelerometerUpdateInterval = 0.1

// get current accelerometerData
if self.motionManager.accelerometerAvailable {

    // operation main queue
    let mainQueue: NSOperationQueue = NSOperationQueue.mainQueue()

    // start accelerometer updates
    self.motionManager.startAccelerometerUpdatesToQueue(mainQueue, withHandler: { (accelerometerData:CMAccelerometerData?, error:NSError?) -> Void in
        // errors
        if (error != nil) {
            print("error: \(error?.localizedDescription)")
        }else{
            // success
            if ((accelerometerData) != nil) {

                // get accelerations values
                let x:String = NSString(format: "%.2f", (accelerometerData?.acceleration.x)!) as String
                let y:String = NSString(format: "%.2f", (accelerometerData?.acceleration.y)!) as String
                let z:String = NSString(format: "%.2f", (accelerometerData?.acceleration.z)!) as String

                print("x: \(x)")
                print("y: \(y)")
                print("z: \(z)")

                // set text labels
                self.xValues.setText(x)
                self.yValues.setText(y)
                self.zValues.setText(z)
            }
        }
    })
}
