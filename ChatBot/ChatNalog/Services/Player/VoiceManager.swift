//
//  VoiceManager.swift
//  ChatBot
//
//  Created by iOS dev on 29/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import AVFoundation

final class VoiceManager: NSObject {
    // MARK: - Logger
    private let eventLogger: FirebaseEventManager = .shared
    
    // MARK: - Audio
    private let recordingSession: AVAudioSession! = .sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
        
    // MARK: - Completions
    var audioPlayerDidFinished: (() -> Void)?
    var audioRecordingDidFinished: ((String?) -> Void)?

    static let shared = VoiceManager()
        
    override private init() {
        super.init()
    }
    
    func permission() {
        requestPermission {_ in }
    }
    
    func startRecording() {
        stopPlaying()

        var allowed = false
        requestPermission { ok in
            allowed = ok
        }
        guard allowed else { return }
        
        let audioFilename = getFileURL(name: "input.wav")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
//            AVLinearPCMIsFloatKey: false,
//            AVLinearPCMIsBigEndianKey: true,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
            ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
        } catch (let error) {
            print(error)
            finishRecording(success: false)
        }
    }
    
    func stopRecording() {
        guard audioRecorder != nil else { return }
        audioRecorder?.stop()
        audioRecorder = nil
        
        let input = getFileURL(name: "input.wav") as URL

        guard FileManager.default.fileExists(atPath: input.path) else {
            self.audioRecordingDidFinished?(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: input)
            let text = data.base64EncodedString()
            print(text)
            self.audioRecordingDidFinished?(text)
            //completion(.success(data))
        } catch {
            self.audioRecordingDidFinished?(nil)
            //completion(.failure(.doesntExist))
        }
        //}
    }
    
    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    func startPlaying() {
        stopPlaying()
        preparePlayer()
        audioPlayer?.play()
        
        eventLogger.logEvent(input: .init(.voice(.playQuestion)))
    }
    
    func pausePlaying() {
        audioPlayer?.pause()
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
    }
    
    private func preparePlayer() {
        var error: NSError?
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            let data = try Data(contentsOf: getFileURL() as URL)
            audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
            audioPlayerDidFinished?()
        }
        
        if let err = error {
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 10.0
        }
    }
    
    //MARK: To upload audio on server
    func uploadAudio(text: String) {}
}

private extension VoiceManager {
    func requestPermission(completion: @escaping (Bool)->()) {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                completion(allowed)
                //DispatchQueue.main.async {
                    //if allowed {
                        //self.loadRecordingUI()
                        
                    //} else {
                        // failed to record!
                    //}
                //}
            }
        } catch {
            // failed to record!
            completion(false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileURL(name: String = "input.mp3") -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(name)
        return path as URL
    }
}

extension VoiceManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate  {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        eventLogger.logEvent(input: .init(.voice(.record)))

        if !flag {
            finishRecording(success: false)
        } else {
            stopRecording()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(error?.localizedDescription ?? "")")
    }
        
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayerDidFinished?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error while playing audio \(error?.localizedDescription ?? "")")
    }
}
