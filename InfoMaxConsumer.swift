//
//  InfoMaxConsumer.swift
//  SwiftNDN
//
//  Created by Akash Kapoor on 4/15/15.
//  Copyright (c) 2015 CyPhy Labs UIUC. All rights reserved.
//

import Foundation
import SwiftNDN

/**
 * Delegate to handle asynchronous InfoMaxConsumer requests.
 */
public protocol InfoMaxConsumerDelegate: class {
    func onOpen()
    func onClose()
    func onData(i: Interest, d: Data)
    func onError(reason: String)
}

public class InfoMaxConsumer: FaceDelegate {
    
    // Special characters to be added to the interests.
    private var INFOMAX_INTEREST_TAG = ""
    private var INFOMAX_INTEREST_AUX_CHAR: Character!
    private var INFOMAX_NEIGHBOR_INTEREST_TAG = ""

    // Array containing last received InfoMaxList
    var infoMaxList: [String] = []
    var infoMaxListIndex: Int = -1
    
    weak var delegate: InfoMaxConsumerDelegate!
    
    private var face: Face!
    private var interestPrefix: String!
    private var interestPrefixName: Name!
    
    /**
     * Create an instance of InfoMaxConsumer. 
     * The interests will be forwarded to the specified forwarder.
     */
    public init(delegate: InfoMaxConsumerDelegate, prefix: String, forwarderIP: String, forwarderPort: UInt16) {
        INFOMAX_INTEREST_AUX_CHAR = "#"
        INFOMAX_INTEREST_TAG = "/InfoMax/"
        INFOMAX_NEIGHBOR_INTEREST_TAG = "/InfoMaxNeighbor"
        
        self.delegate = delegate
        
        interestPrefix = prefix
        interestPrefixName = Name(url: self.interestPrefix)
        
        face = Face(delegate: self, host: forwarderIP, port: forwarderPort)
        face.open()
    }
    
    /**
     * Close the InfoMax connection.
     */
    public func close() {
        face.close()
    }
    
    /**
     * Get objects related to the specified prefix according to the least shared prefix order.
     */
    public func get(count: Int){
        expressInfoMaxInterest(count)
    }
    
    /**
    * Get objects related to the specified suffix according to the most shared prefix order.
    */
    public func getNearestNeighbor(suffix: String) {
        expressNearestNeighborInterest(suffix)
    }
    
    private func expressNearestNeighborInterest(suffix: String) {
        var interest = Interest()
        var nameUrl:String!
        nameUrl = self.interestPrefix + self.INFOMAX_NEIGHBOR_INTEREST_TAG + suffix
        println("Info: InfoMaxConsumer expressing *NN* Interest: " + nameUrl)
        interest.name = Name(url: nameUrl)!
        interest.setInterestLifetime(1000)
        interest.setMustBeFresh()
        self.face.expressInterest(interest, onData: { [unowned self] in self.onInfoMaxList($0, d0: $1) }, onTimeout: { [unowned self] in self.onInfoMaxTimeout($0) })
    }
    
    private func expressInfoMaxInterest(count: Int) {
        var interest = Interest()
        var nameUrl:String!
        nameUrl = self.interestPrefix + self.INFOMAX_INTEREST_TAG + String(self.INFOMAX_INTEREST_AUX_CHAR)
        nameUrl = nameUrl + String(count) + String(self.INFOMAX_INTEREST_AUX_CHAR) + "0"
        println("Info: InfoMaxConsumer expressing IM Interest: " + nameUrl)
        interest.name = Name(url: nameUrl)!
        interest.setInterestLifetime(1000)
        interest.setMustBeFresh()
        self.face.expressInterest(interest, onData: { [unowned self] in self.onInfoMaxList($0, d0: $1) }, onTimeout: { [unowned self] in self.onInfoMaxTimeout($0) })
    }
    
    private func onInfoMaxNNList(i0: Interest, d0: Data) {
        println("Info: InfoMaxNNConsumer - received InfoMaxNNList")
    }
    
    private func onInfoMaxList(i0: Interest, d0: Data) {
        println("Info: InfoMaxConsumer - received InfoMaxList")
        var a = d0.getContent()
        var list = NSString(bytes: a, length: a.count, encoding: NSUTF8StringEncoding)
        var elements = list?.componentsSeparatedByString(" ")
        println("Info: List- ")
        println(elements)
        
        elementArray.removeAll(keepCapacity: true)
        
        for element in elements as! [String] {
            if count(element) > 3 {
                elementArray.append(element)
            }
        }
        if elementArray.count > 0 {
            elementIndex = 0
        }
        getNextElement()
    }
    
    private func getNextElement() {
        println("in get Nex" + String(elementIndex) + String(elementArray.count))
        if (elementIndex > -1 && elementIndex < elementArray.count) {
            println("Over here")
            var interest = Interest()
            var element = elementArray[elementIndex]
            println("Info: InfoMaxConsumer expressing Interest: " + element)
            interest.name = Name(url: interestPrefix+element)!
            interest.setInterestLifetime(1000)
            interest.setMustBeFresh()
            self.face.expressInterest(interest, onData: { [unowned self] in self.onElement($0, d0: $1) }, onTimeout: { [unowned self] in self.onElementTimeout($0) })
            elementIndex = elementIndex + 1
        }
    }
    
    private func onInfoMaxTimeout(i0: Interest) {
        println("Error: InfoMaxConsumer - timeout for " + i0.name.toUri())
    }
    
    private func onElement(i0: Interest, d0: Data) {
        println("Info: Received element - " + i0.name.toUri())
        var applicationInterestName = Name()
        
        for index in interestPrefixName.size...i0.name.size {
            if var component = i0.name.getComponentByIndex(index) {
                applicationInterestName.appendComponent(component)
            }
        }
        i0.name = applicationInterestName
        delegate.onData(i0, d: d0)
        getNextElement()
    }
    private func onElementTimeout(i0: Interest) {
        println("Error: Timeout for " + i0.name.toUri())
    }
        
    // Face Delegate Functions
    public func onOpen() {
        println("Info: InfoMaxConsumer Open for prefix " + interestPrefix + ".")
        delegate.onOpen()
    }
    
    public func onClose() {
        println("Info: InfoMaxConsumer Close.")
        delegate.onClose()
    }
    
    public func onError(reason: String) {
        println("ERROR: InfoMaxConsumer - " + reason)
    }

}