//
//  AudioFeatureExtractor.swift
//  Whoisspeaking
//
//  Created by RongWei Ji on 11/19/23.
//

import Foundation
import AudioKit
import AVFoundation
import SoundpipeAudioKit
import AudioKitEX
import UIKit

class AudioFeatureExtractor {
    let engine = AudioEngine()
    var mic: AudioEngine.InputNode!
    var tracker: PitchTap!
    var silence: Fader!
    let BUFFER_SIZE:Int=8192
   

    init() {
        // Set up AudioKit components
        guard let input = engine.input else {
                   // UIApplication.shared.alert(body: "Could not find Input!")
                    fatalError("engine.input not found! Are you running in the sim?")
                }

        guard let device = engine.inputDevice else {
                    //UIApplication.shared.alert(body: "Could not find Input Device!")
                    fatalError("engine.inputDevice not found! Are you running in the sim?")
                }
        
        tracker = PitchTap(mic, handler: {pitch,amp in
            DispatchQueue.main.async {
                self.pichHandle(pitch: pitch[0], amp: amp[0])
            }
        })
        silence = Fader(mic, gain: 0)


    }
    
    func pichHandle(pitch:AUValue ,amp:AUValue){
        print("\(pitch)")
    }

    func start() {
        self.engine.output=silence
        do {
            try self.engine.start()
            mic.start()
        } catch {
            AudioKit.Log("AudioKit did not start!")
        }
    }

    func stop() {
        mic.avAudioNode.removeTap(onBus: 0)
        mic.stop()
    }

    // TODO
    func extractMFCCs() -> [Double] {
        // Get MFCCs using AudioKit's AKFrequencyTracker
        let mfccs = tracker.amplitude
        return []
    }

    //TODO
    func extractF0() -> Double {
        // Get fundamental frequency (F0) using AudioKit's AKFrequencyTracker
        let frequency = tracker.leftPitch
        return Double(frequency)
    }

    func extractFeatures() -> [Double] {
        // Extract both MFCCs and F0
        let mfccs = extractMFCCs()
        let f0 = extractF0()

        // Combine features into a single array
        var features = mfccs
        features.append(f0)

        return features
    }
}
