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

protocol AudioFeatureExtractorDelegate {
    
    func audioFeatureExtract(trackedSamples: [Float], samplesBufferSize: Int, trackedFrequency:Double, trackedAmplitude:Double)
    
}

class AudioFeatureExtractor {
    let engine = AudioEngine()
    let initialDevice: Device
    var mic: AudioEngine.InputNode!
    var tracker: PitchTap!
    var silence: Fader!
    let BUFFER_SIZE:Int=4096
    var trackedSamples = [Float]()
    var trackedAmplitude:Double = 0
    var trackedFrequency:Double = 0
    var delegate:AudioFeatureExtractorDelegate?
    
    
    init() {
        // Set up AudioKit components
        guard let input = engine.input else { fatalError() }
        guard let device = engine.inputDevice else { fatalError() }
        initialDevice = device
        mic=input
        tracker = PitchTap(mic, handler: {pitch,amp in // the buffer size default is 4096
            DispatchQueue.main.async {
                self.pichHandle(pitch: pitch[0], amp: amp[0])
            }
        })
        silence = Fader(mic, gain: 0)
    }
    
    func pichHandle(pitch:AUValue ,amp:AUValue){
        print("pitch\(pitch)")
        print("amp\(amp)")
    }
    
    func start() {
        self.engine.output=silence
        do {
            try self.engine.start()
            mic.start()
            tracker.start()
        } catch {
            AudioKit.Log("AudioKit did not start!")
        }
    }

    func stop() {
        mic.stop()
    }

    
    func signalTracker(didReceivedBuffer buffer: AVAudioPCMBuffer, atTime time: AVAudioTime){
            
            let elements = UnsafeBufferPointer(start: buffer.floatChannelData?[0], count:self.BUFFER_SIZE)
            
            self.trackedSamples.removeAll()
            
            for i in 0..<self.BUFFER_SIZE {
                self.trackedSamples.append(elements[i])
            }
            
        self.trackedAmplitude = Double(tracker.amplitude)
        self.trackedFrequency = Double(tracker.leftPitch)

        delegate!.audioFeatureExtract(trackedSamples: self.trackedSamples, samplesBufferSize: self.BUFFER_SIZE, trackedFrequency:self.trackedFrequency, trackedAmplitude:self.trackedAmplitude)
            
    }
}
