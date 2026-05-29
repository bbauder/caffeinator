//
//  DBG.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import Foundation

public class DBG {

    /// This is the primary helper function to call. The others can be called if you need specific elements for display or logging.
    ///
    /// Example:
    ///     Call:     print(DBG.str("Moving into the \(newState) on the \(DBG.threadName())"))
    ///     Result: "[DBG] (07:18:17.160) Moving into the foreground on the [MAIN THREAD]"
    ///
    /// - Parameters:
    ///   - outStr: The debug string you intend to print or log. For example:
    ///             "Calling fetcher on thread \(DBG.threadName())"
    ///   - includeTimestamp: Defaults to true
    ///   - includeDate: Defaults to false, so only the time is returned in HH:MM:SS.millis form.
    ///   - prefix: Defaults to "[DBG]". Use this to specify something different.
    /// - Returns: A string suitable for printing or logging.
    static public func str(_ outStr: String,
                           includeTimestamp: Bool = true,
                           includeDate: Bool = false,
                           prefix: String = "[DBG]") -> String {
        if includeTimestamp {
            return "\(prefix) (\(dateTime(includeDate: includeDate))) \(outStr)"
        } else {
            return "\(prefix) \(outStr)"
        }
    }

    static public func dateTime(includeDate: Bool = false) -> String {
        let formatter = DateFormatter()

        formatter.timeZone = TimeZone.current
        formatter.dateFormat = includeDate ? "MM/dd/yyyy HH:mm:ss.SSS" : "HH:mm:ss.SSS"

        return formatter.string(from: Date())
    }

    /// Call this to return a string which contains the ID of an instance of an object
    /// - Parameters:
    ///   - instance: Reference to the object instance. This will usually be self
    static public func objectInstanceID(_ instance: AnyObject) -> String {
        let pointer = Unmanaged.passUnretained(instance).toOpaque()
            return "Instance ID: \(pointer)"
    }

    /// Return a string which contains the current thread ID and name if available.
    /// Also indicate whether it is the main thread.
    static public func currentThread() -> String {
        return "\(Thread.current). \(DBG.threadName())"
    }

    /// Return a string which indicates whether the current thread is the main thread or not.
    static public func threadName() -> String {
        if Thread.isMainThread {
            return "[MAIN THREAD]"
        } else {
            var threadID: __uint64_t = 0
            pthread_threadid_np(nil, &threadID)

            return "[BACKGROUND THREAD (ID: \(threadID))]"
        }
    }
}
