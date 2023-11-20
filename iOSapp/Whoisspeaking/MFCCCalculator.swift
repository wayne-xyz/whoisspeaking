//
//  File.swift
//  Whoisspeaking
//
//  Created by RongWei Ji on 11/19/23.
// New feature for continue developing

import Foundation
import Accelerate

class MFCCCalculator {
    let sampleRate: Float
    let frameSize: Int
    let numFilters: Int
    let numCoefficients: Int
    
    init(sampleRate: Float, frameSize: Int, numFilters: Int, numCoefficients: Int) {
        self.sampleRate = sampleRate
        self.frameSize = frameSize
        self.numFilters = numFilters
        self.numCoefficients = numCoefficients
    }
    
    func calculateMFCCs(audioBuffer: [Float]) -> [Float] {
        // Pre-emphasis
        let preEmphasizedSignal = preEmphasis(audioBuffer)
        
        // Apply Hamming window
        let hammingWindow = hammingWindowFunction(size: frameSize)
        var windowedSignal = [Float](repeating: 0.0, count: frameSize)
        vDSP_vmul(preEmphasizedSignal, 1, hammingWindow, 1, &windowedSignal, 1, vDSP_Length(frameSize))
        
        // Compute FFT
        var fftResults = [Float](repeating: 0.0, count: frameSize)
        fft(windowedSignal, &fftResults)
        
        // Compute power spectrum
        _ = [Float](repeating: 0.0, count: frameSize / 2)
      //  vDSP_zvmags(&fftResults, 1, &powerSpectrum, 1, vDSP_Length(frameSize / 2))
        
        // Apply Mel filterbank
        _ = melFilterbankMatrix()
        _ = [Float](repeating: 0.0, count: numFilters)
      //  vDSP_mmul(melFilterbank, 1, &powerSpectrum, 1, &melFilteredSpectrum, 1, vDSP_Length(numFilters), vDSP_Length(frameSize / 2))
        
        // Take the logarithm of the filterbank energies
        _ = [Float](repeating: 0.0, count: numFilters)
    //    vDSP_vdbcon(melFilteredSpectrum, 1, 1, &logMelEnergies, 1, vDSP_Length(numFilters), 1)
        
        // Compute DCT
        let mfccs = [Float](repeating: 0.0, count: numCoefficients)
        _ = dctMatrixFunction(size: numFilters, numCoefficients: numCoefficients)
    //    vDSP_mmul(dctMatrix, 1, &logMelEnergies, 1, &mfccs, 1, vDSP_Length(numCoefficients), 1, vDSP_Length(numFilters))
        
        return mfccs
    }
    
    private func preEmphasis(_ signal: [Float]) -> [Float] {
        var result = [Float](signal)
        vDSP_deq22(signal, 1, [0.97], &result, 1, vDSP_Length(signal.count - 1))
        return result
    }
    
    private func hammingWindowFunction(size: Int) -> [Float] {
        var window = [Float](repeating: 0.0, count: size)
        vDSP_hamm_window(&window, vDSP_Length(size), 0)
        return window
    }
    
    private func fft(_ input: [Float], _ output: inout [Float]) {
        _ = [Float](input)
        _ = [Float](repeating: 0.0, count: input.count)
   //     var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imaginaryPart)
        let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(input.count))), FFTRadix(kFFTRadix2))
   //     vDSP_fft_zrip(fftSetup!, &splitComplex, 1, vDSP_Length(log2(Float(input.count))), FFTDirection(FFT_FORWARD))
        vDSP_destroy_fftsetup(fftSetup)
  //      vDSP_ztoc(&splitComplex, 1, &output, 2, vDSP_Length(input.count / 2))
    }
    
    private func melFilterbankMatrix() -> [[Float]] {
        // Compute Mel filterbank matrix
        // You can customize this part based on your requirements
        // For simplicity, I'll provide a basic example
        
        // Define the Mel filterbank
        let melFilterbank = computeMelFilterbank()
        
        // Create a matrix for the filterbank
        var melFilterbankMatrix = [[Float]](repeating: [Float](repeating: 0.0, count: frameSize / 2), count: numFilters)
        
        // Populate the matrix
        for i in 0..<numFilters {
            for j in 0..<(frameSize / 2) {
                melFilterbankMatrix[i][j] = melFilterbank[i][j]
            }
        }
        
        return melFilterbankMatrix
    }
    
    private func computeMelFilterbank() -> [[Float]] {
        // You can customize this part based on your requirements
        // For simplicity, I'll provide a basic example
        
        // Define the Mel filterbank
        var melFilterbank = [[Float]](repeating: [Float](repeating: 0.0, count: frameSize / 2), count: numFilters)
        
        // Compute the Mel filterbank
        // This is just an example, you may want to adjust the filterbank
        let lowFreq = 0.0
        let highFreq = Double(sampleRate) / 2.0
        let melLow = hzToMel(lowFreq)
        let melHigh = hzToMel(highFreq)
        
        for i in 0..<numFilters {
            let melCenter = melLow + ((melHigh - melLow) / Double(numFilters + 1)) * Double(i + 1)
            for j in 0..<(frameSize / 2) {
                let freq = melToHz(melCenter)
                melFilterbank[i][j] = triangularFilter(freq, melLow: melToHz(melLow), melHigh: melToHz(melHigh), centerFreq: freq)
            }
        }
        
        return melFilterbank
    }
    
    private func hzToMel(_ hz: Double) -> Double {
        return 2595 * log10(1 + hz / 700)
    }
    
    private func melToHz(_ mel: Double) -> Double {
        return 700 * (pow(10, mel / 2595) - 1)
    }
    
    private func triangularFilter(_ freq: Double, melLow: Double, melHigh: Double, centerFreq: Double) -> Float {
        let slope = 1.0 / (centerFreq - melLow)
        let intercept = -slope * melLow
        return max(0, min(Float(slope * freq + intercept), Float(slope * freq + intercept - 1.0 / (centerFreq - melHigh))))
    }
    
    private func dctMatrixFunction(size: Int, numCoefficients: Int) -> [[Float]] {
        // Compute DCT matrix
        var dctMatrix = [[Float]](repeating: [Float](repeating: 0.0, count: numCoefficients), count: size)
        
        let sqrt2OverN = sqrt(2.0 / Float(size))
        let sqrt1OverN = sqrt(1.0 / Float(size))
        
        for i in 0..<size {
            for j in 0..<numCoefficients {
                dctMatrix[i][j] = j == 0 ? sqrt1OverN * cos(Float.pi * Float(i) * (2.0 * Float(j) + 1) / (2.0 * Float(size))) : sqrt2OverN * cos(Float.pi * Float(i) * (2.0 * Float(j) + 1) / (2.0 * Float(size)))
            }
        }
        
        return dctMatrix
    }
}
