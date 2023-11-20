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
    
  //  func audioFeatureExtract(trackedSamples: [Float], samplesBufferSize: Int, trackedFrequency:Double, trackedAmplitude:Double)
    func audioFeatureExtract(pitch:Double,amp:Double)
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
        delegate!.audioFeatureExtract(pitch: Double(pitch), amp: Double(amp))
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

}
