//
//  GifMaker.swift
//  Wind
//
//  Created by Егор on 5/9/17.
//  Copyright © 2017 Yegor's Mac. All rights reserved.
//

import Foundation
import ImageIO
import AppKit

class GifMaker{

    private var images:[CGImage]!
    private var quality:Float
    private var scale:Float
    private var fps:Float
    private var path:NSURL
    private var processingQueue:DispatchQueue!
    private var dispatchGroup:DispatchGroup!
    private var destinationGIF:CGImageDestination!
    private let gifProperties:[String:Any]!
    private var dictInUse:CFDictionary!
    typealias SuccessBlock = (Bool)->()

    let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
    var frameProperties: CFDictionary {
        return [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 1 / self.fps]] as CFDictionary
    }
    
    init(quality: Float,scale:Float, fps:Float, path:NSURL) {
        self.quality = quality / 100
        self.scale = scale / 100
        self.fps = fps
        self.path = path
        self.images = [CGImage]()
        processingQueue = DispatchQueue(label: "processingQ", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: self.processingQueue)
        self.dispatchGroup = DispatchGroup()
        gifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String:self.fps, kCGImagePropertyGIFHasGlobalColorMap as String: false ]]
        self.dictInUse = gifProperties as CFDictionary
    }
    
    func addImageIntoGif(image:CGImage){
//        self.processingQueue.async(group: self.dispatchGroup, qos: .background, flags: .enforceQoS, execute: {
//            self.images.append(image.resizeImage(level: self.quality, scale: self.scale))
//        })
        self.processingQueue.async {
            self.images.append(image.resizeImage(level: self.quality, scale: self.scale))
        }
    }
    
    
    func generateGif(success: @escaping SuccessBlock){
        destinationGIF = CGImageDestinationCreateWithURL(self.path, kUTTypeGIF, self.images.count, nil)
        CGImageDestinationSetProperties(destinationGIF, fileProperties)
        self.processingQueue.async(group: self.dispatchGroup, qos: .background, flags: .enforceQoS, execute: {
            while self.images.count > 0 {
                CGImageDestinationAddImage(self.destinationGIF, self.images.removeFirst(), self.frameProperties)
            }
        })
        self.dispatchGroup.notify(queue: self.processingQueue, execute: {
           success(CGImageDestinationFinalize(self.destinationGIF))
            self.destinationGIF = nil
        })
    }
    
    
}

