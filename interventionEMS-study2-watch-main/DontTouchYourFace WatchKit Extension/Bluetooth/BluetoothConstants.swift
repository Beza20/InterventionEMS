//
//  BluetoothConstants.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Yujie Tao on 11/27/21.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import CoreBluetooth

enum BluetoothConstants {
    static let name: String = "BARBluetooth"
    /// An identifier for the sample service.
    static let sampleServiceUUID = CBUUID(string: "ABAB")
    
    /// An identifier for the sample characteristic.
    static let sampleCharacteristicUUID = CBUUID(string: "BBBB")
    
    /// The defaults key that will be used for persisting the most recently received data.
    static let receivedDataKey = "received-data"
}
