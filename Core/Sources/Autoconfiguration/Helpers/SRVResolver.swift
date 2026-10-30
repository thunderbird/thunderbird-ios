// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import dnssd

// Use Apple `dnssd` to resolve DNS service (SRV) records
// Adapted from https://github.com/jamf/NoMAD-2/blob/main/NoMAD/SRVLookups/SRVResolver.swift
class SRVResolver {
    let timeoutInterval: TimeInterval

    func query(_ query: String) async throws -> [SRVRecord] {
        try await withCheckedThrowingContinuation { continuation in
            self.query(query) { result in
                switch result {
                case .success(let records):
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    init(timeoutInterval: TimeInterval = 1.0) {
        self.timeoutInterval = timeoutInterval
    }

    private typealias Completion = (Result<[SRVRecord], Error>) -> Void

    private var completion: Completion?
    private var records: [SRVRecord] = []
    private var query: String?
    private var dispatchSourceRead: DispatchSourceRead?
    private var timeoutTimer: DispatchSourceTimer?
    private var serviceRef: DNSServiceRef?
    private var socket: dnssd_sock_t = -1

    private let queue: DispatchQueue = DispatchQueue(label: "SRV")
    private let callback: DNSServiceQueryRecordReply = { _, flags, _, _, _, _, _, rdlen, rdata, _, context in
        guard let context else { return }
        let resolver: SRVResolver = Unmanaged.fromOpaque(context).takeUnretainedValue()
        if let bytes = rdata?.assumingMemoryBound(to: UInt8.self),
            let record: SRVRecord = try? SRVRecord(Data(bytes: bytes, count: Int(rdlen)))
        {
            resolver.records.append(record)
        }
        if (flags & kDNSServiceFlagsMoreComing) == 0 {
            resolver.cancel()
            resolver.completion?(.success(resolver.records))
        }
    }

    private func query(_ query: String, completion: Completion? = nil) {
        self.completion = completion
        self.query = query
        let error: DNSServiceErrorType = DNSServiceQueryRecord(
            &serviceRef,
            kDNSServiceFlagsReturnIntermediates,
            UInt32(0),
            query.cString(using: .utf8),
            UInt16(kDNSServiceType_SRV),
            UInt16(kDNSServiceClass_IN),
            callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        switch error {
        case DNSServiceErrorType(kDNSServiceErr_NoError):
            guard let serviceRef else {
                fail()
                return
            }
            socket = DNSServiceRefSockFD(serviceRef)
            guard socket != -1 else {
                fail()
                return
            }
            dispatchSourceRead = DispatchSource.makeReadSource(fileDescriptor: socket, queue: queue)
            dispatchSourceRead?.setEventHandler {
                guard DNSServiceProcessResult(serviceRef) != kDNSServiceErr_NoError else { return }
                self.fail()
            }
            dispatchSourceRead?.setCancelHandler {
                DNSServiceRefDeallocate(serviceRef)
            }
            dispatchSourceRead?.resume()
            timeoutTimer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timeoutTimer?.setEventHandler {
                self.fail()
            }
            timeoutTimer?.schedule(deadline: .now() + timeoutInterval, repeating: .infinity, leeway: .never)
            timeoutTimer?.resume()
        default:
            fail()
        }
    }

    private func fail() {
        cancel()
        completion?(.failure(URLError(.cannotFindHost)))
    }

    private func cancel() {
        dispatchSourceRead?.cancel()
        timeoutTimer?.cancel()
    }
}
