//
//  ABVideoHelper.swift
//  selfband
//
//  Created by Oscar J. Irun on 27/11/16.
//  Copyright © 2016 appsboulevard. All rights reserved.
//

import UIKit
import AVFoundation

class ABVideoHelper: NSObject {

    static func thumbnailFromVideo(_ asset: AVAsset, time: CMTime) -> UIImage{
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        do{
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        }catch{
            print("Could not generate image: \(error)")
        }
        return UIImage()
    }
    
    static func videoDuration(_ videoURL: URL) -> Float64{
        let source = AVURLAsset(url: videoURL)
        return CMTimeGetSeconds(source.duration)
    }
    
}
