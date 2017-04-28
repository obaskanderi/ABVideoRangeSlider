//
//  ViewController.swift
//  ABVideoRangeSlider
//
//  Created by Oscar J. Irun on 27/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import ABVideoRangeSlider
import AVKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var videoRangeSlider: ABVideoRangeSlider!
    @IBOutlet var playerView: UIView!
    @IBOutlet var lblStart: UILabel!
    @IBOutlet var lblEnd: UILabel!
    @IBOutlet var lblMinSpace: UILabel!
    @IBOutlet var lblProgress: UILabel!
    @IBOutlet var playButton: UIButton!
    
    @IBAction func playVideoPressed(_ sender: Any) {
        if !isPlaying {
            player.play()
            playButton.setTitle("Pause", for: .normal)
        } else {
            player.pause()
            playButton.setTitle("Play", for: .normal)
        }
        isPlaying = !isPlaying
    }
     
    let path = Bundle.main.path(forResource: "test", ofType:"mp4")
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isPlaying = false
    var isSeekInProgress = false
    var chaseTime = kCMTimeZero
    
    fileprivate var startTime = 50
    fileprivate var endTime = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let asset = AVURLAsset(url: URL(fileURLWithPath: path!))
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        
        self.player =  AVPlayer(playerItem: playerItem)
        _ = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 10), queue: DispatchQueue.main, using: { [weak self] (elapsedTime: CMTime) in
            guard let sself = self else { return }
            sself.observeTime(elapsedTime)
        })
        player.actionAtItemEnd = .pause
        
        self.playerLayer = AVPlayerLayer(player: player)
        self.view.layer.addSublayer(playerLayer)
    }

    override func viewWillAppear(_ animated: Bool) {
        videoRangeSlider.videoURL = URL(fileURLWithPath: path!)
        videoRangeSlider.delegate = self
        videoRangeSlider.minSpace = 15.0
        videoRangeSlider.isTimeViewSticky = true
        
        videoRangeSlider.colorScheme = .gray
        videoRangeSlider.overlayColor = .black
//        videoRangeSlider.maxSpace = 180.0

        lblMinSpace.text = "\(videoRangeSlider.minSpace)"
        
        // Set initial position of Start Indicator
        videoRangeSlider.startPosition = Float(startTime)
        
        // Set initial position of End Indicator
        videoRangeSlider.endPosition = Float(endTime)
        
        /* Uncomment to customize the Video Range Slider */
/*
        let customStartIndicator =  UIImage(named: "CustomStartIndicator")
        videoRangeSlider.setStartIndicatorImage(image: customStartIndicator!)
        
        let customEndIndicator =  UIImage(named: "CustomEndIndicator")
        videoRangeSlider.setEndIndicatorImage(image: customEndIndicator!)
        
        let customBorder =  UIImage(named: "CustomBorder")
        videoRangeSlider.setBorderImage(image: customBorder!)
         
        let customProgressIndicator =  UIImage(named: "CustomProgress")
        videoRangeSlider.setProgressIndicatorImage(image: customProgressIndicator!)
*/

        // Customize starTimeView endTimeView
        videoRangeSlider.startTimeView.marginLeft = 2.0
        videoRangeSlider.startTimeView.marginRight = 2.0
        videoRangeSlider.startTimeView.timeLabel.textColor = .black
        videoRangeSlider.startTimeView.backgroundView.backgroundColor = .clear
    
        videoRangeSlider.endTimeView.marginLeft = 2.0
        videoRangeSlider.endTimeView.marginRight = 2.0
        videoRangeSlider.endTimeView.timeLabel.textColor = .black
        videoRangeSlider.endTimeView.backgroundView.backgroundColor = .clear
    }
    
    override func viewDidLayoutSubviews() {
        playerLayer.frame = CGRect(x: 15, y: 30, width: self.view.bounds.width - 30, height: 100)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if player.currentItem?.status == .readyToPlay {
            let seekToTime = CMTimeMake(Int64(startTime), 1)
            stopPlayingAndSeekSmoothlyToTime(seekToTime)
        }
    }
    
    fileprivate func observeTime(_ elapsedTime: CMTime) {
        if isPlaying {
            let seconds = CMTimeGetSeconds(player.currentTime())
            videoRangeSlider.updateProgressIndicator(seconds)
        
            if Float(seconds) >= videoRangeSlider.endPosition {
                isPlaying = false
                player.pause()
                playButton.setTitle("Play", for: .normal)
                stopPlayingAndSeekSmoothlyToTime(CMTimeMake(Int64(startTime), 1))
                videoRangeSlider.updateProgressIndicator(Float64(startTime))
            }
        }
    }

    // MARK: AVPlayer Helper functions to seek
    
    func stopPlayingAndSeekSmoothlyToTime(_ newChaseTime: CMTime) {
        player.pause()
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime;
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
    
    func trySeekToChaseTime() {
        if player.status == .unknown {
            // wait until item becomes ready (KVO player.currentItem.status)
        } else if player.status == .readyToPlay {
            actuallySeekToTime()
        }
    }
    
    func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player.seek(to: seekTimeInProgress, toleranceBefore: kCMTimeZero,
                    toleranceAfter: kCMTimeZero, completionHandler:
            { (isFinished:Bool) -> Void in
                
                if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                    self.isSeekInProgress = false
                } else {
                    self.trySeekToChaseTime()
                }
        })
    }
}

extension ViewController: ABVideoRangeSliderDelegate {
    
    func didChangeValue(_ videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        lblStart.text = "\(startTime)"
        lblEnd.text = "\(endTime)"
        
        self.startTime = Int(startTime)
        self.endTime = Int(endTime)
        
        if startTime > 0 || endTime < videoRangeSlider.duration {
            videoRangeSlider.colorScheme = .green
        } else {
            videoRangeSlider.colorScheme = .gray
        }
    }
    
    func indicatorDidChangePosition(_ videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        lblStart.text = "\(position)"
        lblProgress.text = "\(position)"
        
        let seekToTime = CMTimeMake(Int64(position), 1)
        stopPlayingAndSeekSmoothlyToTime(seekToTime)
    }
    
    func onThumbnailsReady() {
        print(#function)
    }
}
