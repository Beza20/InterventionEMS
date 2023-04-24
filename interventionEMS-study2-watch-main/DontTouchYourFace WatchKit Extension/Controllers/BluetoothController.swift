//
//  BluetoothController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Yujie Tao on 11/27/21.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit
import UIKit

final class BluetoothController:WKInterfaceController{
    private let receiver = BluetoothReceiver(service:BluetoothConstants.sampleServiceUUID,characteristic:BluetoothConstants.sampleCharacteristicUUID)
    
    @IBOutlet weak var scanButton: WKInterfaceButton!
    @IBOutlet weak var sendPulseButton: WKInterfaceButton!
    @IBOutlet weak var disconnectButton:WKInterfaceButton!
    
    
    
    @IBAction func onScan() {
        if receiver.isScanning {
            print("stop scanning")
            
            scanButton.setTitle("Scan")
            receiver.stopScanning()
            
        } else {
            print("start scanning")
        
            scanButton.setTitle("Scanning")
            receiver.startScanning()
            
        }
    }
    
    @IBAction func onSendPulse(){
        print(receiver.discoveredPeripherals)
        if receiver.discoveredPeripherals.count != 0{
            receiver.connect(to: Array(receiver.discoveredPeripherals)[0])
            receiver.writeVal(to: Array(receiver.discoveredPeripherals)[0])
        } else{
            if receiver.connectedPeripheral != nil{
                receiver.writeVal(to: receiver.connectedPeripheral!)
            }
            print("no found peripheral")
        }
    }
    
    @IBAction func onDisconnect(){
        receiver.disconnect(from: receiver.connectedPeripheral!)
    }
    
//    private func update_discovered(){
//        while receiver.isScanning {
//            print(Array(receiver.discoveredPeripherals))
//        }
//    }

}
