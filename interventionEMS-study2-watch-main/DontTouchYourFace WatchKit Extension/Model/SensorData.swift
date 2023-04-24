//
//  SensorData.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 11/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

enum SensorType {
	case userAcceleration
	case magnetometer
	case gravity
//    case attitude
}

protocol SensorData {
	var x: Double { get }
	var y: Double { get }
	var z: Double { get }
	var isAlertConditionVerified: Bool { get }
}

struct UserAccelerationData: SensorData {
	let x: Double
	let y: Double
	let z: Double
	var slope: Slope? = nil

	var isAlertConditionVerified: Bool {
		guard let slope = slope else {
			return false
		}
		return slope == .up
	}
}

struct GravityData: SensorData {
	let x: Double
	let y: Double
	let z: Double
	let pitch: Double

    var pitchMinUpper: Double? = nil
    var pitchMaxUpper: Double? = nil

    var pitchMinLower: Double? = nil
    var pitchMaxLower: Double? = nil
    var isAlertConditionVerified: Bool {
//        print([x,y,z,pitch])
        print(pitch)
        return (pitch >= pitchMinLower! && pitch <= pitchMaxLower!) || (pitch >= pitchMinUpper! && pitch <= pitchMaxUpper!)
//		return pitch >= 40 && pitch <= 100
	}
}

struct MagnetometerData: SensorData {
	let x: Double
	let y: Double
	let z: Double
//	var average: Double? = nil
//	var standardDeviation: Double? = nil
//	var factor: Double? = nil
    var xMinUpper: Double? = nil
    var yMinUpper: Double? = nil
    var zMinUpper: Double? = nil
    var xMaxUpper: Double? = nil
    var yMaxUpper: Double? = nil
    var zMaxUpper: Double? = nil
    
    var xMinLower: Double? = nil
    var yMinLower: Double? = nil
    var zMinLower: Double? = nil
    var xMaxLower: Double? = nil
    var yMaxLower: Double? = nil
    var zMaxLower: Double? = nil
    
	var norm: Double {
		let powNorm = pow(x, 2) + pow(y, 2) + pow(z, 2)
		return sqrt(powNorm)
	}

	var isAlertConditionVerified: Bool {
//		guard
//            let average = average
//		else {
//			return false
//		}
        
        if (x>=xMinUpper! && x<=xMaxUpper! && y>=yMinUpper! && y<=yMaxUpper! && z>=zMinUpper! && z<=zMaxUpper!){
            return true
        } else{
            if (x>=xMinLower! && x<=xMaxLower! && y>=yMinLower! && y<=yMaxLower! && z>=zMinLower! && z<=zMaxLower!){
                return true
            }
            return false
        }
	}
}
