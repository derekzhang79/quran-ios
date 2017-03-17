//
//  ThreadSafeDownloadSessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/16/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

protocol URLSessionDownloadHandler: URLSessionDownloadDelegate {
    var backgroundSessionCompletionHandler: (() -> Void)? { get set }

    func populateOnGoingDownloads(from downloadTasks: [URLSessionTask])
    func addOnGoingDownloads(_ downloads: [DownloadNetworkResponse])
    func getOnGoingDownloads() -> [[DownloadNetworkResponse]]
}

class ThreadSafeDownloadSessionDelegate: NSObject, URLSessionDownloadDelegate {

    private let handler: URLSessionDownloadHandler
    private let queue: OperationQueue

    var backgroundSessionCompletionHandler: (() -> Void)? {
        get { return handler.backgroundSessionCompletionHandler }
        set { handler.backgroundSessionCompletionHandler = newValue }
    }

    init(handler: URLSessionDownloadHandler, queue: OperationQueue) {
        self.handler = handler
        self.queue = queue
    }

    func populateOnGoingDownloads(from session: URLSession) {
        session.getTasks()
            .then { (_, _, downloadTasks) in
                self.queue.promise {
                    self.handler.populateOnGoingDownloads(from: downloadTasks)
                }
            }.catch { error in
                Crash.recordError(error, reason: "While populateOnGoingDownloads")
        }
    }

    func addOnGoingDownloads(_ downloads: [DownloadNetworkResponse]) {
        queue.addOperation {
            self.handler.addOnGoingDownloads(downloads)
        }
    }

    func getOnGoingDownloads() -> Promise<[[DownloadNetworkResponse]]> {
        return queue.promise {
            self.handler.getOnGoingDownloads()
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        handler.urlSession?(session,
                            downloadTask: downloadTask,
                            didWriteData: bytesWritten,
                            totalBytesWritten: totalBytesWritten,
                            totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        handler.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        handler.urlSession?(session, task: task, didCompleteWithError: error)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        handler.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
    }
}
