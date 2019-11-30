//
//  VoiceManager.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 29/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation
import AVFoundation

final class VoiceManager: NSObject {
    
    private let recordingSession: AVAudioSession! = .sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    var audioPlayerDidFinished: (() -> Void)?
        
    override init() {
        super.init()
    }
    
    func startRecording() {
        var allowed = false
        requestPermission { ok in
            allowed = ok
        }
        guard allowed else { return }
        
        let audioFilename = getFileURL()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFileWAVEType),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            //AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: true,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            //recordButton.setTitle("Tap to Stop", for: .normal)
            //playButton.isEnabled = false
        } catch (let error) {
            print(error)
            finishRecording(success: false)
        }
    }
    
    func stopRecording() {
        guard audioRecorder != nil else { return }
        audioRecorder?.stop()
        audioRecorder = nil
        
        let input = getFileURL() as URL
        //let output = getFileURL(name: "ouput.wav") as URL
        
//        var options = AKConverter.Options()
//        options.format = "wav"
//        let converter = AKConverter(inputURL: input, outputURL: output, options: options)
//
//        converter.start { error in
//            guard error == nil else { return }

            if FileManager.default.fileExists(atPath: input.path) {
                do {
                    let data = try Data(contentsOf: input)
                    let str = data.base64EncodedString()
                    //completion(.success(data))
                } catch {
                    //completion(.failure(.doesntExist))
                }
            }
            
        //}
    }
    
    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        
        if success {
            //recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            //recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    func startPlaying() {
        preparePlayer()
        audioPlayer?.play()
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
    
    //MARK: To upload video on server
    
    func uploadAudioToServer() {
        /*Alamofire.upload(
         multipartFormData: { multipartFormData in
         multipartFormData.append(getFileURL(), withName: "audio.m4a")
         },
         to: "https://yourServerLink",
         encodingCompletion: { encodingResult in
         switch encodingResult {
         case .success(let upload, _, _):
         upload.responseJSON { response in
         Print(response)
         }
         case .failure(let encodingError):
         print(encodingError)
         }
         })*/
    }
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
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(error!.localizedDescription)")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayerDidFinished?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error while playing audio \(error!.localizedDescription)")
    }
}
