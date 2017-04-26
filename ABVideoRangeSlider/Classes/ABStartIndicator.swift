//
//  ABStartIndicator.swift
//  selfband
//
//  Created by Oscar J. Irun on 27/11/16.
//  Copyright © 2016 appsboulevard. All rights reserved.
//

import UIKit

class ABStartIndicator: UIView {
    
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        
        let bundle = Bundle(for: ABStartIndicator.self)
        let image = UIImage(named: "LeftArrow", in: bundle, compatibleWith: nil)
    
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = frame.height / 2
        let width = frame.width / 2
        let x = (frame.width - width) / 2
        let y = (frame.height - height) / 2
        imageView.frame = CGRect(x: x, y: y, width: width, height: height)
        
        let rectShape = CAShapeLayer()
        rectShape.bounds = frame
        rectShape.position = center
        let pos = floor(bounds.width / 2)
        rectShape.path = UIBezierPath(roundedRect: CGRect(x: -pos, y: 0, width: bounds.width, height: bounds.height), byRoundingCorners: [.bottomLeft, .topLeft], cornerRadii: CGSize(width: pos, height: pos)).cgPath
        layer.mask = rectShape
    }
}
