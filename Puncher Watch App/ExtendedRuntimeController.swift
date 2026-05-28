//
//  ExtendedRuntimeController.swift
//  Puncher Watch App
//
//  Created by Codex on 2026/5/28.
//

import Foundation
import WatchKit

@MainActor
final class ExtendedRuntimeController: NSObject, WKExtendedRuntimeSessionDelegate {
    var onMessageChange: ((String?) -> Void)?

    private var session: WKExtendedRuntimeSession?
    private var isActive = false
    private var isStopping = false

    private(set) var message: String? {
        didSet {
            onMessageChange?(message)
        }
    }

    func start() {
        guard !isActive else {
            return
        }

        isActive = true
        isStopping = false
        message = nil

        let session = WKExtendedRuntimeSession()
        session.delegate = self
        self.session = session
        session.start()
    }

    func stop() {
        isStopping = true
        isActive = false
        session?.invalidate()
        session = nil
        message = nil
    }

    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor [weak self] in
            self?.isActive = true
            self?.message = nil
        }
    }

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor [weak self] in
            self?.message = "锁屏监听即将结束，请重新打开 App 继续保持监听。"
        }
    }

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let wasStopping = isStopping
            isActive = false
            isStopping = false
            session = nil

            guard !wasStopping else {
                return
            }

            if let error {
                message = "锁屏监听未能启动：\(error.localizedDescription)"
            } else {
                message = "锁屏监听已结束，请重新打开 App 启动监听。"
            }
        }
    }
}
