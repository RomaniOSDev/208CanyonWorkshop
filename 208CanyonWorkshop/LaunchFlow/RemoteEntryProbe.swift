//
//  RemoteEntryProbe.swift
//  157Countdown
//

import Foundation

/// GET preflight with redirect follow-up; returns final response URL when 2xx.
final class RemoteEntryProbe {

    private let session: URLSession
    private var task: URLSessionDataTask?
    private let timeout: TimeInterval
    private let maxAttempts: Int

    init(
        timeout: TimeInterval = 12,
        maxAttempts: Int = 2,
        session: URLSession = .shared
    ) {
        self.timeout = timeout
        self.maxAttempts = max(1, maxAttempts)
        self.session = session
    }

    func probe(
        entryURL: URL,
        onProgress: ((Double) -> Void)? = nil,
        completion: @escaping (Bool, URL?) -> Void
    ) {
        cancel()
        onProgress?(0.2)
        attempt(entryURL: entryURL, remainingAttempts: maxAttempts, onProgress: onProgress, completion: completion)
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    private func attempt(
        entryURL: URL,
        remainingAttempts: Int,
        onProgress: ((Double) -> Void)?,
        completion: @escaping (Bool, URL?) -> Void
    ) {
        var request = URLRequest(url: entryURL)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout

        let attemptIndex = maxAttempts - remainingAttempts + 1

        task = session.dataTask(with: request) { [weak self] _, response, error in
            guard let self else { return }
            self.task = nil

            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                self.logProbeResponse(entryURL: entryURL, attempt: attemptIndex, http: nil, error: error, cancelled: true)
                LaunchFlowLogger.debug("Preflight cancelled")
                return
            }

            if let error {
                self.logProbeResponse(entryURL: entryURL, attempt: attemptIndex, http: response as? HTTPURLResponse, error: error)
                LaunchFlowLogger.debug("Preflight error: \(error.localizedDescription)")
                if remainingAttempts > 1 {
                    self.attempt(
                        entryURL: entryURL,
                        remainingAttempts: remainingAttempts - 1,
                        onProgress: onProgress,
                        completion: completion
                    )
                } else {
                    onProgress?(1.0)
                    completion(false, nil)
                }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                self.logProbeResponse(entryURL: entryURL, attempt: attemptIndex, http: nil, error: nil)
                LaunchFlowLogger.debug("Preflight: no HTTP response")
                completion(false, nil)
                return
            }

            self.logProbeResponse(entryURL: entryURL, attempt: attemptIndex, http: http, error: nil)
            LaunchFlowLogger.debug("Preflight status: \(http.statusCode)")
            onProgress?(0.85)

            let isOK = (200...299).contains(http.statusCode)
            if isOK {
                let finalURL = http.url ?? entryURL
                LaunchFlowLogger.debug("Preflight OK — final URL resolved")
                onProgress?(1.0)
                completion(true, finalURL)
            } else if remainingAttempts > 1 {
                self.attempt(
                    entryURL: entryURL,
                    remainingAttempts: remainingAttempts - 1,
                    onProgress: onProgress,
                    completion: completion
                )
            } else {
                onProgress?(1.0)
                completion(false, nil)
            }
        }
        print("[LaunchFlow] Probe start — attempt \(attemptIndex)/\(maxAttempts), GET \(entryURL.absoluteString)")
        task?.resume()
    }

    private func logProbeResponse(
        entryURL: URL,
        attempt: Int,
        http: HTTPURLResponse?,
        error: Error?,
        cancelled: Bool = false
    ) {
        if cancelled {
            print("[LaunchFlow] Probe cancelled — attempt \(attempt), url=\(entryURL.absoluteString)")
            return
        }
        if let error {
            let status = (http?.statusCode).map(String.init) ?? "—"
            print("[LaunchFlow] Probe failed — attempt \(attempt), status=\(status), error=\(error.localizedDescription), url=\(entryURL.absoluteString)")
            return
        }
        guard let http else {
            print("[LaunchFlow] Probe failed — attempt \(attempt), no HTTP response, url=\(entryURL.absoluteString)")
            return
        }
        let final = http.url?.absoluteString ?? entryURL.absoluteString
        let ok = (200...299).contains(http.statusCode)
        print("[LaunchFlow] Probe response — attempt \(attempt), status=\(http.statusCode), ok=\(ok), finalURL=\(final), requestURL=\(entryURL.absoluteString)")
    }
}
