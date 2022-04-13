//
//  MusicPlayer.swift
//  AnimalPark
//
//  Created by Alexis Mendiola on 2022-03-27.
//

import Foundation
import AVFoundation

class MusicPlayer {
    static let Instance = MusicPlayer() // Singleton Instance
    private var audioPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    
    func startBgMusic() {
        if let bundle = Bundle.main.path(forResource: "haru-ni-yosete", ofType: "wav") {
            let bgm = NSURL(fileURLWithPath: bundle)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bgm as URL)
                guard let audioPlayer = audioPlayer else { return }
                audioPlayer.numberOfLoops = -1 // Loop infinitely
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            } catch {
                print(error)
            }
        }
    }
    
    func stopBgMusic() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.stop()
    }
    
    func playSfx(sfx: String, ext: String) {
        if let bundle = Bundle.main.path(forResource: sfx, ofType: ext) {
            let sfxUrl = NSURL(fileURLWithPath: bundle)
            
            do {
                sfxPlayer = try AVAudioPlayer(contentsOf: sfxUrl as URL)
                guard let sfxPlayer = sfxPlayer else { return }
                sfxPlayer.play() // Plays once without looping
            } catch {
                print(error)
            }
        }
    }
}
