//
//  SensorManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import CoreMotion
import WatchKit
import HealthKit

protocol CalibrationInterface {
    func startMagnetometerCalibration(upper:Bool)
	func startContinousDataUpdates(withHandler: SensorManager.SensorHandler?)
	func stopContinousDataUpdates()
    func stopCalibration(upper: Bool)
}

protocol SensorManagerInterface {
	var isMagnetometerAvailable: Bool { get }
}

final class SensorManager: SensorManagerInterface, CalibrationInterface {
	// MARK: - Nested types
	typealias SensorHandler = ([SensorData]?, Error?) -> Void

	enum SensorError: Error {
		case deviceMotionNotAvailable
		case gravityNotAvailable
		case userAccelerationNotAvailable
	}

	// MARK: - Properties
//	private var magnetometerBuffer: RingBuffer<Double>
	private var armAngleBuffer: RingBuffer<Double>
    
    private var magXBufferUpper: RingBuffer<Double>
    private var magYBufferUpper: RingBuffer<Double>
    private var magZBufferUpper: RingBuffer<Double>
    private var pitchBufferUpper: RingBuffer<Double>
    
    private var magXBufferLower: RingBuffer<Double>
    private var magYBufferLower: RingBuffer<Double>
    private var magZBufferLower: RingBuffer<Double>
    private var pitchBufferLower: RingBuffer<Double>

    private var workoutSession: HKWorkoutSession?
    private lazy var workoutConfiguration: HKWorkoutConfiguration = {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        return workoutConfiguration
    }()

	private let queue: OperationQueue = {
		let queue = OperationQueue()
		queue.qualityOfService = .userInteractive
		return queue
	}()

	private lazy var setupManager: SensorsDataProvider = SetupManager.shared

	private lazy var motionManager: CMMotionManager = {
		let motionManager = CMMotionManager()
		motionManager.deviceMotionUpdateInterval = 1/Constant.sensorDataFrequency
		return motionManager
	}()

	var isMagnetometerAvailable: Bool {
		guard motionManager.isMagnetometerAvailable else {
			#if DEBUG
			return true
			#else
			return false
			#endif
		}
		return true
	}

	lazy var isMagnetometerCollectionDataEnabledFromUser: Bool = {
		guard isMagnetometerAvailable else {
			return false
		}
		return true
	}()

	// MARK: - Init
	static let shared = SensorManager()

	private init() {
//		magnetometerBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        
        // For calibration
        magXBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        magYBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        magZBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        pitchBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        
        magXBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        magYBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        magZBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        pitchBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        
		armAngleBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency * Constant.accelerationCollectionDataSeconds))
        
	}

	// MARK: - Helper functions
    func startMagnetometerCalibration(upper:Bool) {
		// Fresh buffer
//		magnetometerBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        if upper{
            magXBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            magYBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            magZBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            pitchBufferUpper = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            
        } else{
            magXBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            magYBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            magZBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
            pitchBufferLower = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
        }
       
        
        workoutSession = try? HKWorkoutSession(healthStore: .init(), configuration: workoutConfiguration)
        workoutSession?.startActivity(with: nil)
        
		motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}

			// Check if there's any error
			if error != nil {
				return
			}

			guard let deviceMotion = deviceMotion else {
				return
			}

			// Guard if there are data from the magnetometer
			guard let magnetometerData =  _self.sensorData(.magnetometer, deviceMotion: deviceMotion) as? MagnetometerData else {
				return
			}
            // Gravity contains the angle of the inclination of the arm
            guard let gravity = _self.sensorData(.gravity, deviceMotion: deviceMotion) as? GravityData else {
                return
            }
            
            
			// Write the norm of the magnetic field in the buffer
//			_self.magnetometerBuffer.write(magnetometerData.norm)
//
            if (upper){
                _self.magXBufferUpper.write(magnetometerData.x)
                _self.magYBufferUpper.write(magnetometerData.y)
                _self.magZBufferUpper.write(magnetometerData.z)
                _self.pitchBufferUpper.write(gravity.pitch)
            } else{
                _self.magXBufferLower.write(magnetometerData.x)
                _self.magYBufferLower.write(magnetometerData.y)
                _self.magZBufferLower.write(magnetometerData.z)
                _self.pitchBufferLower.write(gravity.pitch)
            }
		}
	}
    
    
    func stopCalibration(upper:Bool){
        stopContinousDataUpdates()
        if (upper){
            let minX = magXBufferUpper.min
            let minY = magYBufferUpper.min
            let minZ = magZBufferUpper.min
            let maxX = magXBufferUpper.max
            let maxY = magYBufferUpper.max
            let maxZ = magZBufferUpper.max
            
            let pitchMin = pitchBufferUpper.min
            let pitchMax = pitchBufferUpper.max
            
            print("MAGMAX \([maxX, maxY, maxZ])")
            print("MAGMIN \([minX, minY, minZ])")
            print("PITCH  \([pitchMin, pitchMax])")
        
        } else{
            let minX = magXBufferLower.min
            let minY = magYBufferLower.min
            let minZ = magZBufferLower.min
            let maxX = magXBufferLower.max
            let maxY = magYBufferLower.max
            let maxZ = magZBufferLower.max
            
            let pitchMin = pitchBufferLower.min
            let pitchMax = pitchBufferLower.max
            
            print("MAGMAX \([maxX, maxY, maxZ])")
            print("MAGMIN \([minX, minY, minZ])")
            print("PITCH \([pitchMin, pitchMax])")
        }
    
        workoutSession?.end()
    }
    
 
	func startContinousDataUpdates(withHandler: SensorHandler? = nil) {
		motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}

			// Call handler to ensure the callback is being propagated on the main queue
			let callHandler: SensorHandler = { deviceMotion, error in
				DispatchQueue.main.async {
					withHandler?(deviceMotion, error)
				}
			}

			// Check if there's any error
			if let error = error {
				callHandler(nil, error)
				return
			}

			guard let deviceMotion = deviceMotion else {
				callHandler(nil, SensorError.deviceMotionNotAvailable)
				return
			}

			// Collect data
			// Gravity contains the angle of the inclination of the arm
			guard var gravity = _self.sensorData(.gravity, deviceMotion: deviceMotion) as? GravityData else {
				callHandler(nil, SensorError.gravityNotAvailable)
				return
			}
			
			_self.armAngleBuffer.write(gravity.pitch)
            gravity.pitchMinUpper = self?.pitchBufferUpper.min
            gravity.pitchMaxUpper = self?.pitchBufferUpper.max

            gravity.pitchMinLower = self?.pitchBufferLower.min
            gravity.pitchMaxLower = self?.pitchBufferLower.max
            

			// From the value of the angles collected inside the buffer,
			// we can determine the slope of the acceleration
			guard var userAcceleration = _self.sensorData(.userAcceleration, deviceMotion: deviceMotion) as? UserAccelerationData else {
				callHandler(nil, SensorError.userAccelerationNotAvailable)
				return
			}

            userAcceleration.slope = _self.armAngleBuffer.slope

			var sensorsData: [SensorData] = [
				gravity,
                userAcceleration,
			]

			// Guard if there are data from the magnetometer
			guard var magnetometer = _self.sensorData(.magnetometer, deviceMotion: deviceMotion) as? MagnetometerData else {
				callHandler(sensorsData, nil)
				return
			}

			// If the x component of the gravity is not between a certain range
			// it means the user is not raising the hand and we want to keep collection
			// data from the magnetometer
			let isInContinuosCalibrationMode = !gravity.isAlertConditionVerified

			// If the user wants to collect the magnetometer data
			if _self.isMagnetometerCollectionDataEnabledFromUser {
				// Update the buffer with the new incoming data if it's in calibration mode
				if isInContinuosCalibrationMode {
//					_self.magnetometerBuffer.write(magnetometer.norm)
					// Set the average for the magnetometer
				}
//				magnetometer.average = _self.magnetometerBuffer.average
            
                magnetometer.xMaxLower = _self.magXBufferLower.max
                magnetometer.yMaxLower = _self.magYBufferLower.max
                magnetometer.zMaxLower = _self.magZBufferLower.max
                magnetometer.xMinLower = _self.magXBufferLower.min
                magnetometer.yMinLower = _self.magYBufferLower.min
                magnetometer.zMinLower = _self.magZBufferLower.min
                
                magnetometer.xMaxUpper = _self.magXBufferUpper.max
                magnetometer.yMaxUpper = _self.magYBufferUpper.max
                magnetometer.zMaxUpper = _self.magZBufferUpper.max
                magnetometer.xMinUpper = _self.magXBufferUpper.min
                magnetometer.yMinUpper = _self.magYBufferUpper.min
                magnetometer.zMinUpper = _self.magZBufferUpper.min
                
				// Append to the list of available sensor's data
				sensorsData.append(magnetometer)
			}
			callHandler(sensorsData, nil)
		}
	}

	func stopContinousDataUpdates() {
		motionManager.stopDeviceMotionUpdates()
	}
}

extension SensorManager {
	private func sensorData(_ type: SensorType, deviceMotion: CMDeviceMotion) -> SensorData? {
		switch type {
		case .magnetometer:
			// If the magnetometer isn't available
            // Yujie: some how isMagnetometerAvailable is always False but still able to get magfield data
//			if !motionManager.isMagnetometerAvailable {
            if !motionManager.isDeviceMotionAvailable {
				// In debug mode add a fake magnetometer data using the user's acceleration
				#if DEBUG
                print("debug mode")
				return MagnetometerData(
					x: deviceMotion.userAcceleration.x,
					y: deviceMotion.userAcceleration.y,
					z: deviceMotion.userAcceleration.z
				)
				#else
				return nil
				#endif
			} else {
				// Otherwhise use the real data
				return MagnetometerData(
					x: deviceMotion.magneticField.field.x,
					y: deviceMotion.magneticField.field.y,
					z: deviceMotion.magneticField.field.z
				)
			}
		case .gravity:
			let x = deviceMotion.gravity.x
			let y = deviceMotion.gravity.y
			let z = deviceMotion.gravity.z
			let pitch: Double = {
				let theta = atan2(-x, sqrt(pow(y, 2) + pow(z, 2))) * (180 / .pi)
				let isOnRightWrist = WKInterfaceDevice.current().wristLocation == .right
				return isOnRightWrist ? -theta : theta
			}()

			let gravitySensorData = GravityData(
				x: x,
				y: y,
				z: z,
				pitch: pitch
			)
			return gravitySensorData
		case .userAcceleration:
			let userAcceleration = UserAccelerationData(
				x: deviceMotion.gravity.x,
				y: deviceMotion.gravity.y,
				z: deviceMotion.gravity.z
			)
			return userAcceleration
		}
	}
}
