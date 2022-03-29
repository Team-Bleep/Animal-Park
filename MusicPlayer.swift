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
    var audioPlayer: AVAudioPlayer?
    
    func startBgMusic() {
        print("begin startBgMusic")
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
    
    func playSfx(sfx: String, ext: String) {
        if let bundle = Bundle.main.path(forResource: sfx, ofType: ext) {
            let sfxUrl = NSURL(fileURLWithPath: bundle)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: sfxUrl as URL)
                guard let audioPlayer = audioPlayer else { return }
                audioPlayer.numberOfLoops = 1 // Play sfx without looping
                audioPlayer.play()
            } catch {
                print(error)
            }
        }
    }
}
