//
//  ExtensionDelegate.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit
import CoreBluetooth
import os.log

class ExtensionDelegate: NSObject, WKExtensionDelegate, BluetoothReceiverDelegate{

    private let logger = Logger(
        subsystem: BluetoothConstants.name,
        category: String(describing: ExtensionDelegate.self)
    )
    
    private var currentRefreshTask: WKRefreshBackgroundTask?
    
    private(set) var bluetoothReceiver: BluetoothReceiver!
    
    override init() {
        super.init()
        
        bluetoothReceiver = BluetoothReceiver(
            service: BluetoothConstants.sampleServiceUUID,
            characteristic: BluetoothConstants.sampleCharacteristicUUID
        )
        
        bluetoothReceiver.delegate = self
    }
    
    func applicationDidFinishLaunching() {
		let setupManager: OnboardingProvider = SetupManager.shared

		guard setupManager.didUserAcceptPrivacy else {
			WKInterfaceController.reloadRootPageControllers(withNames: [PrivacyInterfaceController.identifier], contexts: nil, orientation: .vertical, pageIndex: 0)
			return
		}

		if SensorManager.shared.isMagnetometerAvailable {
			guard setupManager.didUserMakeFirstCalibration else {
				WKInterfaceController.reloadRootPageControllers(withNames: [CalibrationInterfaceController.identifier], contexts: nil, orientation: .vertical, pageIndex: 0)
				return
			}
		}

		WKInterfaceController.reloadRootPageControllers(withNames: [MeasurementInterfaceController.identifier], contexts: nil, orientation: .vertical, pageIndex: 0)
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                
                logger.info("handling background app refresh task")
                
                /// Check to see if you disconnected from any peripherals. If not, then end the background refresh task.
                guard let peripheral = bluetoothReceiver.knownDisconnectedPeripheral, shouldReconnect(to: peripheral) else {
                    logger.info("no known disconnected peripheral to reconnect to")
                    completeRefreshTask(refreshTask)
                    return
                }
                
                /// Reconnect to the known disconnected bluetooth peripheral and read its characteristic value.
                bluetoothReceiver.connect(to: peripheral)
                
                refreshTask.expirationHandler = {
                    self.logger.info("background runtime is about to expire")
                    
                    /// When the background refresh task is about to expire, disconnect from the peripheral if you have not done so already
                    if let peripheral = self.bluetoothReceiver.connectedPeripheral {
                        self.bluetoothReceiver.disconnect(from: peripheral)
                    }
                }
                
                currentRefreshTask = refreshTask
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: .distantFuture, userInfo: nil)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
        
    }
    
    private func shouldReconnect(to peripheral: CBPeripheral) -> Bool {
        /// Implement your own logic to determine if the peripheral should be reconnected.
        return true
    }
    
    private func completeRefreshTask(_ task: WKRefreshBackgroundTask) {
        logger.info("setting background app refresh task as complete")
        task.setTaskCompletedWithSnapshot(false)
    }
    
    // MARK: BluetoothReceiverDelegate
    
    func didCompleteDisconnection(from peripheral: CBPeripheral) {
        /// If the peripheral completes its disconnection and you are handling a background refresh task, then complete the task.
        if let refreshTask = currentRefreshTask {
            completeRefreshTask(refreshTask)
            currentRefreshTask = nil
        }
    }
    
    func didFailWithError(_ error: BluetoothReceiverError) {
        /// If the `BluetoothReceiver` fails and you are handling a background refresh task, then complete the task.
        if let refreshTask = currentRefreshTask {
            completeRefreshTask(refreshTask)
            currentRefreshTask = nil
        }
    }
    
    func didReceiveData(_ data: Data) {
        guard let value = try? JSONDecoder().decode(Int.self, from: data) else {
            logger.error("failed to decode float from data")
            return
        }
        
        logger.info("received value from peripheral: \(value)")
        UserDefaults.standard.setValue(value, forKey: BluetoothConstants.receivedDataKey)
        
        ComplicationController.updateAllActiveComplications()
        
        /// When you are handling a background refresh task and are done interacting with the peripheral, disconnect from it as soon as possible.
        if currentRefreshTask != nil, let peripheral = bluetoothReceiver.connectedPeripheral {
            bluetoothReceiver.disconnect(from: peripheral)
        }
    }
}
