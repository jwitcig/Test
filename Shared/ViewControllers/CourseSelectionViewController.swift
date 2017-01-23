//
//  CourseSelectionViewController.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import AVFoundation
import UIKit

import Cartography
import iMessageTools

class AudioPlayer: NSObject {
    
    static let main = AudioPlayer()
    
    fileprivate var player: AVAudioPlayer?
    
    var volume: Float {
        get { return player?.volume ?? 1 }
        set { player?.volume = newValue }
    }
    
    var completion: (()->Void)?
    
    var wasInterrupted = false
    
    func play(_ fileName: String, ofType fileType: String = "mp3", completion: (()->Void)? = nil) {
        guard let url = Bundle(for: AudioPlayer.self).url(forResource: fileName, withExtension: fileType) else { return }
        
        self.completion = completion

        DispatchQueue.main.async {
            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.delegate = self
                self.player?.prepareToPlay()
                self.resume()
            } catch {
                print("audio error: \(error)")
            }
        }
    }
    
    func resume() {
        player?.prepareToPlay()
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func playInterrupt(notification: Notification) {
        //Check the type of notification, especially if you are sending multiple AVAudioSession events here
        if notification.name == NSNotification.Name.AVAudioSessionInterruption {
            
            let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSessionInterruptionType
            
            if let type = interruptionType, type == .began {
                
            } else {
                DispatchQueue.main.async(execute: resume)
            }
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion?()
    }
}

class CourseSelectionViewController: UIViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    let contentView = UIView()
    
    @IBOutlet weak var headerView: UIView!
    
    var mainController: MessagesViewController!
    
    var messageSender: MessageSender?
    var orientationManager: OrientationManager?
    
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "courseSelectionBackground"))
    
        scrollView.addSubview(contentView)
        constrain(contentView, scrollView) {
            $0.leading == $1.leading
            $0.trailing == $1.trailing
            $0.top == $1.top
            $0.bottom == $1.bottom
            
            $0.width == $1.width
        }
    
        headerView.backgroundColor = .clear
        contentView.addSubview(headerView)
        
        constrain(headerView, contentView) {
            $0.top == $1.top
            $0.centerX == $1.centerX
            $0.width == $1.width
            $0.height == 52
        }
        
        let playBlock: (CoursePack.Type)->Void = { course in
            let controller = self.mainController.createGameController()
            self.mainController.gameController = controller
            controller.messageSender = self.messageSender
            controller.orientationManager = self.orientationManager
            controller.configureScene(previousSession: nil, course: course)
            self.mainController.present(controller)
           
            AudioPlayer.main.play("click")
        }
        
        let courses: [CoursePack.Type] = [
            Frost.self,
            Blaze.self,
            Retro.self,
            Nebula.self,
        ]
        let previews: [CoursePreviewView] = courses.map {
            let preview = CoursePreviewView.create(course: $0)
            preview.playPressedBlock = playBlock
            return preview
        }
        
        previews.forEach(contentView.addSubview)
        
        if let first = previews.first {
            constrain(first, contentView, headerView) {
                $0.width == $1.width * 0.9
                $0.height == 100
                
                $0.centerX == $1.centerX
                
                $0.top == $2.bottom 
            }
        }
        
        if let last = previews.last {
            constrain(last, contentView) {
                $0.bottom == $1.bottom - 20
            }
        }
        
        for (index, preview) in previews[0..<previews.count].enumerated() {
            if (0..<previews.count).contains(index-1) {
                let previous = previews[index-1]
                
                constrain(preview, previous) {
                    $0.width == $1.width
                    $0.height == $1.height
                    
                    $0.top == $1.bottom + 10
                    $0.centerX == $1.centerX
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        mainController?.gameController?.scene?.audio.backgroundMusic?.pause()
    }
}
