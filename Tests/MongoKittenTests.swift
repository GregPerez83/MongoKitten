//
//  MongoKittenTests.swift
//  MongoKittenTests
//
//  Created by Joannis Orlandos on 31/01/16.
//  Copyright © 2016 PlanTeam. All rights reserved.
//

import XCTest
import BSON
import When
import MongoKitten

class MongoKittenTests: XCTestCase {
    var server: Server = try! Server(host: "127.0.0.1", port: 27017, autoConnect: false)
    var testDatabase: Database { return server["mongokitten-unittest"] }
    var testCollection: Collection { return testDatabase["testcol"] }
    
    override func setUp() {
        super.setUp()
        
        if !server.connected {
            try! server.connectSync()
        }
        
        
        // Erase the testing database:
        for aCollection in try! testDatabase.getCollections() {
            try! aCollection.drop()
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        //        try! server.disconnect()
    }
    
    func testSetup() {
        let server2 = try! Server(host: "127.0.0.1", port: 27017, autoConnect: true)
        
        do {
            // Should fail
            try server2.connectSync()
            XCTFail()
            
        } catch { }
        
        // This one should work
        try! server2.disconnect()
        
        do {
            // This one should NOT work
            try server2.disconnect()
            XCTFail()
        } catch {}
        
        do {
            try server2["test"]["test"].insertSync(["shouldnt": "beinserted"])
            XCTFail()
        } catch {}
    }
    
    func testQuery() {
        try! testCollection.insertSync(["query": "test"])
        try! testCollection.insertAllSync([["double": 2], ["double": 2]])
        
        do {
            let document = try! testCollection.findOne(["query": "test"])
            
            XCTAssert(document!["query"] as! String == "test")
        }
        
        do {
            let documents = try! testCollection.find(["double": 2])
            
            var count = 0
            for document in documents{
                count += 1
                XCTAssert(document["double"] as! Int == 2)
            }
            
            XCTAssert(count == 2)
        }
    }
    
    func testInsert() {
        try! testCollection.insertSync([
            "double": 53.2,
            "64bit-integer": 52,
            "32bit-integer": Int32(20),
            "embedded-document": *["double": 44.3, "_id": ObjectId()],
            "embedded-array": *[44, 33, 22, 11, 10, 9],
            "identifier": ObjectId(),
            "datetime": NSDate(),
            "bool": false,
            "null": Null(),
            "binary": Binary(data: [0x01, 0x02]),
            "string": "Hello, I'm a string!"
            ])
        
        try! testCollection.insertAllSync([["hont": "kad"], ["fancy": 3.14], ["documents": true]])
        
        // TODO: validate!
    }
    
    func testListCollectionsWithoutCollections() {
        // TODO: Finish this test
        let _ = try! testDatabase.getCollectionInfos()
    }
    
    func testListCollectionsWithCollections() {
        // TODO: Finish this test
        
        // Create 200 collections, yay!
        // okay, the daemon crashes on 200 collections. 50 for now
        for i in 0..<50 {
            try! testDatabase["collection\(i)"].insertSync(["Test document for collection \(i)"])
        }
        
        let info = Array(try! testDatabase.getCollectionInfos())
        XCTAssert(info.count == 50)
        
        var counter = 0
        for collection in try! testDatabase.getCollections() {
            XCTAssert(Array(try! collection.find()).first![0]!.stringValue!.containsString("Test document for collection"))
            counter += 1
        }
        XCTAssert(counter == 50)
        
    }
    
    func testUpdate() {
        try! testCollection.insertSync(["honten": "hoien"])
        try! testCollection.update(["honten": "hoien"], updated: ["honten": 3])
        
        let doc = try! testCollection.findOne()!
        XCTAssert(doc["honten"] as! Int == 3)
        
    }
    
    // MARK: - Insert Performance
    func testSmallTransactionInsertPerformance() {
        // Test inserting lots of small documents in multiple transactions
        let collection = server["test"]["test"]
        let doc: Document = ["test": "Beautiful string", "4": 32480.2, "henk": *["hallo", 4]]
        self.measureBlock {
            for _ in 0...1000 {
                try! collection.insertSync(doc)
            }
        }
    }
    
    func testMassiveTransactionInsertPerformance() {
        // Test inserting lots of small documents in a single transaction
        let collection = server["test"]["test"]
        let doc: Document = ["test": "Beautiful string", "4": 32480.2, "henk": *["hallo", 4]]
        
        // Test inserting a batch of small documents
        let arr = Array(count: 1000, repeatedValue: doc)
        self.measureBlock {
            try! collection.insertAllSync(arr)
        }
    }
}
