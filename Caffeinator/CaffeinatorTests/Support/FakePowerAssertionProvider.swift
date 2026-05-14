//
//  FakePowerAssertionProvider.swift
//  CaffeinatorTests
//

import Foundation
import IOKit.pwr_mgt
@testable import Caffeinator

final class FakePowerAssertionProvider: PowerAssertionProvider, @unchecked Sendable {

    struct CreateCall: Equatable {
        let type: String
        let reason: String
    }

    private(set) var createCalls: [CreateCall] = []
    private(set) var releasedIDs: [IOPMAssertionID] = []
    private(set) var liveIDs = Set<IOPMAssertionID>()
    private var nextID: IOPMAssertionID = 1

    var createSucceeds = true

    func create(type: CFString, reason: CFString) -> IOPMAssertionID? {
        createCalls.append(CreateCall(type: type as String, reason: reason as String))
        guard createSucceeds else {
            return nil
        }
        let id = nextID
        nextID += 1
        liveIDs.insert(id)
        return id
    }

    func release(_ id: IOPMAssertionID) {
        releasedIDs.append(id)
        liveIDs.remove(id)
    }

    var createCount: Int { createCalls.count }
    var liveCount: Int { liveIDs.count }

    func createCount(forType type: CFString) -> Int {
        let target = type as String
        return createCalls.filter { $0.type == target }.count
    }
}
