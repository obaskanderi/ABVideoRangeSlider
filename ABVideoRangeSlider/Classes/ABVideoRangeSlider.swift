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

    // Public Variables
    public weak var delegate: ABVideoRangeSliderDelegate? = nil
    public var minSpace: Float = 1  // In Seconds
    public var maxSpace: Float = 0  // In Seconds
    
    public var isProgressIndicatorSticky: Bool = false
    public var isProgressIndicatorDraggable: Bool = true
    public var isTimeViewSticky: Bool = false
    
    public var startTimeView  = ABTimeView()
    public var endTimeView    = ABTimeView()
    
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
    
    public var duration: Float64 {
        get {
            guard let asset = self.avasset else { return 0 }
            return CMTimeGetSeconds(asset.duration)
        }
    }
    
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
    
    public var progressIndicatorImage: UIImage! {
        didSet {
            self.progressIndicator.imageView.image = progressIndicatorImage
        }
    }
    
    public var isProgressIndicatorHidden: Bool = false {
        didSet {
            self.progressIndicator.isHidden = isProgressIndicatorHidden
        }
    }
    
    public var startIndicatorImage: UIImage! {
        didSet {
            self.startIndicator.imageView.image = startIndicatorImage
        }
    }
    
    public var endIndicatorImage: UIImage! {
        didSet {
            self.endIndicator.imageView.image = endIndicatorImage
        }
    }
    
    public var startPosition: Float = 0 { // In Seconds
        didSet {
            self.startPercentage = self.valueFromSeconds(startPosition)
            self.progressPercentage = self.startPercentage
            layoutSubviews()
        }
    }
    
    public var endPosition: Float = 0 { // In Seconds
        didSet {
            self.endPercentage = self.valueFromSeconds(endPosition)
            if progressPercentage > endPercentage {
                progressPercentage = endPercentage
            }
            layoutSubviews()
        }
    }
    
    override public var frame: CGRect {
        didSet {
            updateThumbnails()
        }
    }
    
    // Private/Internal variables
    
    private enum DragHandleChoice {
        case start
        case end
    }
    
    var startIndicator      = ABStartIndicator()
    var endIndicator        = ABEndIndicator()
    var topLine             = UIView()
    var bottomLine          = UIView()
    var progressIndicator   = ABProgressIndicator()
    var draggableView       = UIView()

    let thumbnailsManager   = ABThumbnailsManager()

    var progressPercentage: CGFloat = 0         // Represented in percentage
    var startPercentage: CGFloat    = 0         // Represented in percentage
    var endPercentage: CGFloat      = 100       // Represented in percentage

    let topBorderHeight: CGFloat      = 5
    let bottomBorderHeight: CGFloat   = 5
    let indicatorWidth: CGFloat = 17.0
    
    var isReceivingGesture: Bool = false
    
    var rightOverlay = UIView()
    var leftOverlay = UIView()

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
                                               action: #selector(startDragged))

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
                                             action: #selector(endDragged))

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
                                                  action: #selector(progressDragged))

        progressIndicator = ABProgressIndicator(frame: CGRect(x: 0,
                                                              y: -topBorderHeight,
                                                              width: 10,
                                                              height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        progressIndicator.addGestureRecognizer(progressDrag)
        progressIndicator.imageView.tintColor = progressIndicatorColor
        self.addSubview(progressIndicator)
        

        // Setup Draggable View

        let viewDrag = UIPanGestureRecognizer(target:self,
                                              action: #selector(viewDragged))

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

    public func updateProgressIndicator(_ seconds: Float64) {
        if !isReceivingGesture {
            let endSeconds = secondsFromValue(self.endPercentage)
            
            if seconds >= endSeconds {
                self.resetProgressPosition()
            } else {
                self.progressPercentage = self.valueFromSeconds(Float(seconds))
            }

            layoutSubviews()
        }
    }

    public func updateThumbnails() {
        guard let asset = self.avasset else { return }
        DispatchQueue.global(qos: .background).async {
            self.thumbnailsManager.generateThumbnails(self, for: asset)
        }
    }

    // MARK: - Private functions

    // MARK: - Crop Handle Drag Functions
    @objc private func startDragged(_ recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer,
            drag: .start,
            currentPositionPercentage: self.startPercentage,
            currentIndicator: self.startIndicator
        )
    }
    
    @objc private func endDragged(_ recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer,
            drag: .end,
            currentPositionPercentage: self.endPercentage,
            currentIndicator: self.endIndicator
        )
    }

    private func processHandleDrag(_ recognizer: UIPanGestureRecognizer,
                                   drag: DragHandleChoice,
                                   currentPositionPercentage: CGFloat,
                                   currentIndicator: UIView) {
        
        self.updateGestureStatus(recognizer)
        
        let translation = recognizer.translation(in: self)
        
        var position: CGFloat = positionFromValue(currentPositionPercentage)
        
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
        
        let startSeconds = secondsFromValue(self.startPercentage)
        let endSeconds = secondsFromValue(self.endPercentage)
        
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        if drag == .start {
            self.startPercentage = percentage
        } else {
            self.endPercentage = percentage
        }
        
        if self.isReceivingGesture {
            self.progressIndicator.alpha = 0
        } else {
            self.progressPercentage = percentage
            let progressSeconds = self.secondsFromValue(progressPercentage)
            self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.progressIndicator.alpha = 1
            }, completion: nil)
        }
        
        layoutSubviews()
    }
    
    func progressDragged(_ recognizer: UIPanGestureRecognizer){
        if !isProgressIndicatorDraggable {
            return
        }
        
        updateGestureStatus(recognizer)
        
        let translation = recognizer.translation(in: self)

        let positionLimitStart  = positionFromValue(self.startPercentage)
        let positionLimitEnd    = positionFromValue(self.endPercentage)

        var position = positionFromValue(self.progressPercentage)
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

        let progressSeconds = secondsFromValue(progressPercentage)

        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)

        self.progressPercentage = percentage

        layoutSubviews()
    }

    func viewDragged(_ recognizer: UIPanGestureRecognizer){
        updateGestureStatus(recognizer)
        
        let translation = recognizer.translation(in: self)

        var progressPosition = positionFromValue(self.progressPercentage)
        var startPosition = positionFromValue(self.startPercentage)
        var endPosition = positionFromValue(self.endPercentage)

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
        
        let startSeconds = secondsFromValue(startPercentage)
        let endSeconds = secondsFromValue(endPercentage)
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        let progressSeconds = startSeconds
        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
        
        self.startPercentage = startPercentage
        self.endPercentage = endPercentage
        self.progressPercentage = startPercentage

        layoutSubviews()
    }
    
    // MARK: - Drag Functions Helpers
    private func positionFromValue(_ value: CGFloat) -> CGFloat{
        let position = value * self.frame.size.width / 100
        return position
    }
    
    private func getPositionLimits(with drag: DragHandleChoice) -> (min: CGFloat, max: CGFloat) {
        if drag == .start {
            return (
                positionFromValue(self.endPercentage - valueFromSeconds(self.minSpace)),
                positionFromValue(self.endPercentage - valueFromSeconds(self.maxSpace))
            )
        } else {
            return (
                positionFromValue(self.startPercentage + valueFromSeconds(self.minSpace)),
                positionFromValue(self.startPercentage + valueFromSeconds(self.maxSpace))
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
    
    private func secondsFromValue(_ value: CGFloat) -> Float64{
        return duration * Float64((value / 100))
    }

    private func valueFromSeconds(_ seconds: Float) -> CGFloat{
        return CGFloat(seconds * 100) / CGFloat(duration)
    }
    
    private func updateGestureStatus(_ recognizer: UIGestureRecognizer) {
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
        let progressPosition = positionFromValue(self.progressPercentage)
        progressIndicator.center = CGPoint(x: progressPosition , y: progressIndicator.center.y)
        
        let startSeconds = secondsFromValue(self.progressPercentage)
        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: startSeconds)
    }

    // MARK: -

    override public func layoutSubviews() {
        super.layoutSubviews()

        if progressPercentage > startPercentage {
            startTimeView.timeLabel.text = self.secondsToFormattedString(secondsFromValue(self.progressPercentage))
        } else {
            startTimeView.timeLabel.text = self.secondsToFormattedString(secondsFromValue(self.startPercentage))
        }
        endTimeView.timeLabel.text = self.secondsToFormattedString(secondsFromValue(self.endPercentage))

        let startPosition = positionFromValue(self.startPercentage)
        let endPosition = positionFromValue(self.endPercentage)
        let progressPosition = positionFromValue(self.progressPercentage)
        
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


    private func secondsToFormattedString(_ totalSeconds: Float64) -> String{
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
