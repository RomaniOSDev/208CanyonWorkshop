//
//  LaunchFlowResolver.swift
//  157Countdown
//

import SwiftUI
import UIKit

/// Orchestrates launch destination: native shell, web document, or staging + probe.
@MainActor
final class LaunchFlowResolver {

    private let sessionStore: LaunchSessionStore
    private let gateEvaluator: CalendarGateEvaluator
    private let urlComposer: RemoteEntryURLComposer
    private let windowPresenter: RootWindowPresenter
    private var activeProbe: RemoteEntryProbe?
    private var stagingProbeCancelled = false

    init(window: UIWindow?) {
        self.sessionStore = LaunchSessionStore.shared
        self.gateEvaluator = CalendarGateEvaluator()
        self.urlComposer = RemoteEntryURLComposer()
        self.windowPresenter = RootWindowPresenter(window: window)
    }

    func resolveEntryViewController() -> UIViewController {
        let destination = resolveDestination()
        LaunchFlowLogger.notice("Resolved destination: \(String(describing: destination))")
        return viewController(for: destination)
    }

    func cancelPendingOperations() {
        stagingProbeCancelled = true
        activeProbe?.cancel()
        activeProbe = nil
        LaunchFlowLogger.debug("Cancelled pending launch probe")
    }

    // MARK: - Destination resolution

    func resolveDestination() -> LaunchDestination {
        #if DEBUG
        switch LaunchFlowDebugOptions.current {
        case .forceNative:
            LaunchFlowLogger.debug("DEBUG override: force native")
            return .native
        case .forceWeb:
            LaunchFlowLogger.debug("DEBUG override: force web")
            if let url = urlComposer.composedURL() ?? sessionStore.savedLastURL {
                return .web(url)
            }
            return .native
        case .forceStaging:
            LaunchFlowLogger.debug("DEBUG override: force staging")
            return .staging
        case .automatic:
            break
        }
        #endif

        if sessionStore.hasShownNativeShell {
            return .native
        }

        if gateEvaluator.isGateOpen() {
            if let saved = sessionStore.savedLastURL {
                return .web(saved)
            }
            return .staging
        } else {
            sessionStore.hasShownNativeShell = true
            return .native
        }
    }

    func viewController(for destination: LaunchDestination) -> UIViewController {
        switch destination {
        case .native:
            return makeNativeHost()
        case .web(let url):
            return makeWebHost(url: url)
        case .staging:
            return makeStagingHost()
        }
    }

    // MARK: - Hosts

    private func makeNativeHost() -> UIViewController {
        sessionStore.hasShownNativeShell = true
        let host = UIHostingController(rootView: ContentView())
        host.modalPresentationStyle = .fullScreen
        return host
    }

    private func makeWebHost(url: URL) -> UIViewController {
        let surface = WebDocumentSurfaceView(url: url) { [weak self] in
            self?.pivotToNative()
        }
        let host = UIHostingController(rootView: surface)
        host.modalPresentationStyle = .fullScreen
        return host
    }

    private func makeStagingHost() -> UIViewController {
        let state = LaunchStagingState()
        let host = UIHostingController(rootView: DeferredLaunchCanvas(state: state))
        host.modalPresentationStyle = .fullScreen

        stagingProbeCancelled = false
        DispatchQueue.main.async { [weak self] in
            self?.runStagingProbe(state: state)
        }
        return host
    }

    private func runStagingProbe(state: LaunchStagingState) {
        guard !stagingProbeCancelled else { return }
        guard let entryURL = urlComposer.composedURL() else {
            LaunchFlowLogger.debug("Invalid composed entry URL")
            finishStaging(success: false, finalURL: nil)
            return
        }

        let probe = RemoteEntryProbe()
        activeProbe = probe
        probe.probe(entryURL: entryURL, onProgress: { value in
            Task { @MainActor in
                state.progress = value
            }
        }, completion: { [weak self] success, finalURL in
            Task { @MainActor in
                self?.activeProbe = nil
                guard let self, !self.stagingProbeCancelled else { return }
                self.finishStaging(success: success, finalURL: finalURL)
            }
        })
    }

    private func finishStaging(success: Bool, finalURL: URL?) {
        if success, let finalURL {
            pivotToWeb(url: finalURL)
        } else {
            sessionStore.hasShownNativeShell = true
            pivotToNative()
        }
    }

    // MARK: - Pivot (after staging)

    func pivotToNative() {
        windowPresenter.crossfade(to: makeNativeHost())
    }

    func pivotToWeb(url: URL) {
        windowPresenter.crossfade(to: makeWebHost(url: url))
    }
}
