//
//  ABVideoRangeSlider.swift
//  selfband
//
//  Created by Oscar J. Irun on 26/11/16.
//  Copyright © 2016 appsboulevard. All rights reserved.
//

import UIKit
import AVFoundation

@objc public protocol ABVideoRangeSliderDelegate: class {
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64)
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64)
    
    @objc optional func sliderGesturesBegan()
    @objc optional func sliderGesturesEnded()
}

public class ABVideoRangeSlider: UIView, UIGestureRecognizerDelegate {

    private enum DragHandleChoice {
        case start
        case end
    }
    
    public weak var delegate: ABVideoRangeSliderDelegate? = nil

    var startIndicator      = ABStartIndicator()
    var endIndicator        = ABEndIndicator()
    var topLine             = UIView()
    var bottomLine          = UIView()
    var progressIndicator   = ABProgressIndicator()
    var draggableView       = UIView()

    public var startTimeView       = ABTimeView()
    public var endTimeView         = ABTimeView()
    
    public var avasset: AVAsset! {
        didSet {
            self.superview?.layoutSubviews()
            self.updateThumbnails()
        }
    }

    public var videoURL: URL! {
        didSet {
            avasset = AVURLAsset(url: videoURL)
        }
    }

    let thumbnailsManager   = ABThumbnailsManager()

    var duration: Float64 {
        get {
            guard let asset = self.avasset else { return 0 }
            return CMTimeGetSeconds(asset.duration)
        }
    }

    var progressPercentage: CGFloat = 0         // Represented in percentage
    var startPercentage: CGFloat    = 0         // Represented in percentage
    var endPercentage: CGFloat      = 100       // Represented in percentage

    let topBorderHeight: CGFloat      = 5
    let bottomBorderHeight: CGFloat   = 5

    let indicatorWidth: CGFloat = 17.0

    public var minSpace: Float = 1              // In Seconds
    public var maxSpace: Float = 0              // In Seconds
    
    public var isProgressIndicatorSticky: Bool = false
    public var isProgressIndicatorDraggable: Bool = true
    public var isTimeViewSticky: Bool = false
    
    var isReceivingGesture: Bool = false
    
    var rightOverlay = UIView()
    var leftOverlay = UIView()

    public var colorScheme: UIColor = .green {
        didSet {
            self.topLine.backgroundColor = colorScheme
            self.bottomLine.backgroundColor = colorScheme
            self.startIndicator.backgroundColor = colorScheme
            self.endIndicator.backgroundColor = colorScheme
        }
    }
    
    public var progressIndicatorColor: UIColor = .white {
        didSet {
            self.progressIndicator.imageView.tintColor = progressIndicatorColor
        }
    }
    
    
    public enum ABTimeViewPosition{
        case top
        case bottom
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup(){
        self.isUserInteractionEnabled = true

        // Setup Start Indicator
        let startDrag = UIPanGestureRecognizer(target:self,
                                               action: #selector(startDragged(recognizer:)))

        startIndicator = ABStartIndicator(frame: CGRect(x: 0,
                                                        y: -topBorderHeight,
                                                        width: indicatorWidth,
                                                        height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        startIndicator.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        startIndicator.addGestureRecognizer(startDrag)
        startIndicator.backgroundColor = colorScheme
        self.addSubview(startIndicator)

        // Setup End Indicator

        let endDrag = UIPanGestureRecognizer(target:self,
                                             action: #selector(endDragged(recognizer:)))

        endIndicator = ABEndIndicator(frame: CGRect(x: 0,
                                                    y: -topBorderHeight,
                                                    width: indicatorWidth,
                                                    height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        endIndicator.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        endIndicator.addGestureRecognizer(endDrag)
        endIndicator.backgroundColor = colorScheme
        self.addSubview(endIndicator)


        // Setup Top and bottom line

        topLine = UIView(frame: CGRect(x: 0,
                                       y: -topBorderHeight,
                                       width: indicatorWidth,
                                       height: topBorderHeight))
        topLine.backgroundColor = colorScheme
        self.addSubview(topLine)

        bottomLine = UIView(frame: CGRect(x: 0,
                                          y: self.frame.size.height,
                                          width: indicatorWidth,
                                          height: bottomBorderHeight))
        bottomLine.backgroundColor = colorScheme
        self.addSubview(bottomLine)

        self.addObserver(self,
                         forKeyPath: "bounds",
                         options: NSKeyValueObservingOptions(rawValue: 0),
                         context: nil)

        // Setup Progress Indicator

        let progressDrag = UIPanGestureRecognizer(target:self,
                                                  action: #selector(progressDragged(recognizer:)))

        progressIndicator = ABProgressIndicator(frame: CGRect(x: 0,
                                                              y: -topBorderHeight,
                                                              width: 10,
                                                              height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        progressIndicator.addGestureRecognizer(progressDrag)
        progressIndicator.imageView.tintColor = progressIndicatorColor
        self.addSubview(progressIndicator)
        

        // Setup Draggable View

        let viewDrag = UIPanGestureRecognizer(target:self,
                                              action: #selector(viewDragged(recognizer:)))

        draggableView.addGestureRecognizer(viewDrag)
        self.draggableView.backgroundColor = .clear
        self.addSubview(draggableView)
        self.sendSubview(toBack: draggableView)

        // Setup time labels

        startTimeView = ABTimeView(size: CGSize(width: 60, height: 30), position: 1)
        startTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addSubview(startTimeView)

        endTimeView = ABTimeView(size: CGSize(width: 60, height: 30), position: 1)
        endTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addSubview(endTimeView)
        
        
        rightOverlay.alpha = 0.8
        rightOverlay.isOpaque = false
        rightOverlay.backgroundColor = UIColor.white
        insertSubview(rightOverlay, belowSubview: startIndicator)
        
        leftOverlay.alpha = 0.8
        leftOverlay.isOpaque = false
        leftOverlay.backgroundColor = UIColor.white
        insertSubview(leftOverlay, belowSubview: endIndicator)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds"{
            self.updateThumbnails()
        }
    }

    // MARK: Public functions

    public func setProgressIndicatorImage(image: UIImage){
        self.progressIndicator.imageView.image = image
    }

    public func hideProgressIndicator(){
        self.progressIndicator.isHidden = true
    }

    public func showProgressIndicator(){
        self.progressIndicator.isHidden = false
    }

    public func updateProgressIndicator(seconds: Float64){
        if !isReceivingGesture {
            let endSeconds = secondsFromValue(value: self.endPercentage)
            
            if seconds >= endSeconds {
                self.resetProgressPosition()
            } else {
                self.progressPercentage = self.valueFromSeconds(seconds: Float(seconds))
            }

            layoutSubviews()
        }
    }

    public func setStartIndicatorImage(image: UIImage){
        self.startIndicator.imageView.image = image
    }

    public func setEndIndicatorImage(image: UIImage){
        self.endIndicator.imageView.image = image
    }

    public func setTimeView(view: ABTimeView){
        self.startTimeView = view
        self.endTimeView = view
    }

    public func setTimeViewPosition(position: ABTimeViewPosition){
        switch position {
        case .top:

            break
        case .bottom:

            break
        }
    }

    public func updateThumbnails(){
        DispatchQueue.global(qos: .background).async {
            self.thumbnailsManager.generateThumbnails(self, for: self.avasset)
        }
    }

    public func setStartPosition(seconds: Float){
        self.startPercentage = self.valueFromSeconds(seconds: seconds)
        self.progressPercentage = self.startPercentage
        layoutSubviews()
    }

    public func setEndPosition(seconds: Float){
        self.endPercentage = self.valueFromSeconds(seconds: seconds)
        layoutSubviews()
    }

    // MARK: - Private functions

    // MARK: - Crop Handle Drag Functions
    @objc private func startDragged(recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer: recognizer,
            drag: .start,
            currentPositionPercentage: self.startPercentage,
            currentIndicator: self.startIndicator
        )
    }
    
    @objc private func endDragged(recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer: recognizer,
            drag: .end,
            currentPositionPercentage: self.endPercentage,
            currentIndicator: self.endIndicator
        )
    }

    private func processHandleDrag(
        recognizer: UIPanGestureRecognizer,
        drag: DragHandleChoice,
        currentPositionPercentage: CGFloat,
        currentIndicator: UIView
        ) {
        
        self.updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)
        
        var position: CGFloat = positionFromValue(value: currentPositionPercentage)
        
        position = position + translation.x
        
        if position < 0 { position = 0 }
        
        if position > self.frame.size.width {
            position = self.frame.size.width
        }

        let positionLimits = getPositionLimits(with: drag)
        position = checkEdgeCasesForPosition(with: position, and: positionLimits.min, and: drag)

        if Float(self.duration) > self.maxSpace && self.maxSpace > 0 {
            if drag == .start {
                if position < positionLimits.max {
                    position = positionLimits.max
                }
            } else {
                if position > positionLimits.max {
                    position = positionLimits.max
                }
            }
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        currentIndicator.center = CGPoint(x: position , y: currentIndicator.center.y)
        
        let percentage = currentIndicator.center.x * 100 / self.frame.width
        
        let startSeconds = secondsFromValue(value: self.startPercentage)
        let endSeconds = secondsFromValue(value: self.endPercentage)
        
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        if drag == .start {
            self.startPercentage = percentage
        } else {
            self.endPercentage = percentage
        }
        
        if self.isReceivingGesture {
            self.progressIndicator.alpha = 0
        } else {
            var progressPosition: CGFloat = 0.0
            if drag == .start {
                progressPosition = self.positionFromValue(value: self.startPercentage)
            } else {
                progressPosition = self.positionFromValue(value: self.endPercentage)
            }
            
            self.progressIndicator.center = CGPoint(x: progressPosition , y: self.progressIndicator.center.y)
            let progressPercentage = self.progressIndicator.center.x * 100 / self.frame.width
            
            if self.progressPercentage != progressPercentage {
                let progressSeconds = self.secondsFromValue(value: progressPercentage)
                self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
            }
            self.progressPercentage = progressPercentage
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.progressIndicator.alpha = 1
            }, completion: nil)
        }
        
        layoutSubviews()
    }
    
    func progressDragged(recognizer: UIPanGestureRecognizer){
        if !isProgressIndicatorDraggable {
            return
        }
        
        updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)

        let positionLimitStart  = positionFromValue(value: self.startPercentage)
        let positionLimitEnd    = positionFromValue(value: self.endPercentage)

        var position = positionFromValue(value: self.progressPercentage)
        position = position + translation.x

        if position < positionLimitStart {
            position = positionLimitStart
        }

        if position > positionLimitEnd {
            position = positionLimitEnd
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        progressIndicator.center = CGPoint(x: position , y: progressIndicator.center.y)

        let percentage = progressIndicator.center.x * 100 / self.frame.width

        let progressSeconds = secondsFromValue(value: progressPercentage)

        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)

        self.progressPercentage = percentage

        layoutSubviews()
    }

    func viewDragged(recognizer: UIPanGestureRecognizer){
        updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)

        var progressPosition = positionFromValue(value: self.progressPercentage)
        var startPosition = positionFromValue(value: self.startPercentage)
        var endPosition = positionFromValue(value: self.endPercentage)

        startPosition = startPosition + translation.x
        endPosition = endPosition + translation.x
        progressPosition = progressPosition + translation.x

        if startPosition < 0 {
            startPosition = 0
            endPosition = endPosition - translation.x
            progressPosition = progressPosition - translation.x
        }

        if endPosition > self.frame.size.width {
            endPosition = self.frame.size.width
            startPosition = startPosition - translation.x
            progressPosition = progressPosition - translation.x
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        progressIndicator.center = CGPoint(x: progressPosition , y: progressIndicator.center.y)
        startIndicator.center = CGPoint(x: startPosition , y: startIndicator.center.y)
        endIndicator.center = CGPoint(x: endPosition , y: endIndicator.center.y)

        let startPercentage = startIndicator.center.x * 100 / self.frame.width
        let endPercentage = endIndicator.center.x * 100 / self.frame.width
        let progressPercentage = progressIndicator.center.x * 100 / self.frame.width

        let startSeconds = secondsFromValue(value: startPercentage)
        let endSeconds = secondsFromValue(value: endPercentage)

        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)

        if self.progressPercentage != progressPercentage {
            let progressSeconds = secondsFromValue(value: progressPercentage)
            self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
        }

        self.startPercentage = startPercentage
        self.endPercentage = endPercentage
        self.progressPercentage = progressPercentage

        layoutSubviews()
    }
    
    // MARK: - Drag Functions Helpers
    private func positionFromValue(value: CGFloat) -> CGFloat{
        let position = value * self.frame.size.width / 100
        return position
    }
    
    private func getPositionLimits(with drag: DragHandleChoice) -> (min: CGFloat, max: CGFloat) {
        if drag == .start {
            return (
                positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: self.minSpace)),
                positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: self.maxSpace))
            )
        } else {
            return (
                positionFromValue(value: self.startPercentage + valueFromSeconds(seconds: self.minSpace)),
                positionFromValue(value: self.startPercentage + valueFromSeconds(seconds: self.maxSpace))
            )
        }
    }
    
    private func checkEdgeCasesForPosition(with position: CGFloat, and positionLimit: CGFloat, and drag: DragHandleChoice) -> CGFloat {
        if drag == .start {
            if Float(self.duration) < self.minSpace {
                return 0
            } else {
                if position > positionLimit {
                    return positionLimit
                }
            }
        } else {
            if Float(self.duration) < self.minSpace {
                return self.frame.size.width
            } else {
                if position < positionLimit {
                    return positionLimit
                }
            }
        }
        
        return position
    }
    
    private func secondsFromValue(value: CGFloat) -> Float64{
        return duration * Float64((value / 100))
    }

    private func valueFromSeconds(seconds: Float) -> CGFloat{
        return CGFloat(seconds * 100) / CGFloat(duration)
    }
    
    private func updateGestureStatus(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            
            self.isReceivingGesture = true
            self.delegate?.sliderGesturesBegan?()
            
        } else if recognizer.state == .ended {
            
            self.isReceivingGesture = false
            self.delegate?.sliderGesturesEnded?()
        }
    }
    
    private func resetProgressPosition() {
        self.progressPercentage = self.startPercentage
        let progressPosition = positionFromValue(value: self.progressPercentage)
        progressIndicator.center = CGPoint(x: progressPosition , y: progressIndicator.center.y)
        
        let startSeconds = secondsFromValue(value: self.progressPercentage)
        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: startSeconds)
    }

    // MARK: -

    override public func layoutSubviews() {
        super.layoutSubviews()

        if progressPercentage > startPercentage {
            startTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.progressPercentage))
        } else {
            startTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.startPercentage))
        }
        endTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.endPercentage))

        let startPosition = positionFromValue(value: self.startPercentage)
        let endPosition = positionFromValue(value: self.endPercentage)
        let progressPosition = positionFromValue(value: self.progressPercentage)

        let height = self.bounds.size.height + bottomBorderHeight + topBorderHeight
        let midY = self.bounds.midY
        startIndicator.bounds.size.height = height
        startIndicator.center = CGPoint(x: startPosition, y: midY)
        
        endIndicator.bounds.size.height = height
        endIndicator.center = CGPoint(x: endPosition, y: midY)
        
        progressIndicator.bounds.size.height = height
        progressIndicator.center = CGPoint(x: progressPosition, y: midY)
        
        draggableView.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.size.width,
                                     y: 0,
                                     width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                     height: self.frame.height)


        topLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                               y: -topBorderHeight,
                               width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                               height: topBorderHeight)

        bottomLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                                  y: self.frame.size.height,
                                  width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                  height: bottomBorderHeight)

        // Update time view
        if isTimeViewSticky {
            startTimeView.frame.origin.x = 0
            endTimeView.frame.origin.x = frame.width - endTimeView.frame.width
        } else {
            startTimeView.center = CGPoint(x: startIndicator.center.x, y: startTimeView.center.y)
            endTimeView.center = CGPoint(x: endIndicator.center.x, y: endTimeView.center.y)
        }
        
        rightOverlay.frame = CGRect(x: 0, y: 0, width: startPosition, height: bounds.height)
        leftOverlay.frame = CGRect(x: endPosition, y: 0, width: bounds.width - endPosition, height: bounds.height)
    }


    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(x: -startIndicator.frame.size.width,
                                    y: -topLine.frame.size.height,
                                    width: self.frame.size.width + startIndicator.frame.size.width + endIndicator.frame.size.width,
                                    height: self.frame.size.height + topLine.frame.size.height + bottomLine.frame.size.height)
        return extendedBounds.contains(point)
    }


    private func secondsToFormattedString(totalSeconds: Float64) -> String{
        let hours:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }

    deinit {
      removeObserver(self, forKeyPath: "bounds")
    }
}
