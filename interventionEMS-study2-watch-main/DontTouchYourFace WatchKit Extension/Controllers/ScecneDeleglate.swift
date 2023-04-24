//
//  ScecneDeleglate.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Yujie Tao on 11/13/21.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import SwiftUI

let contentView = ContentView(motion: MotionManager())
struct ContentView: View {

    @ObservedObject
    var motion: MotionManager

    var body: some View {
        VStack {
            Text("Magnetometer Data")
            Text("X: \(motion.x)")
            Text("Y: \(motion.y)")
            Text("Z: \(motion.z)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(motion: MotionManager())
    }
}
