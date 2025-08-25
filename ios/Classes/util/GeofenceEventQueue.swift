import Foundation

/// Serial task queue to ensure geofence callbacks are processed one at a time
/// with a fixed delay between consecutive tasks.
final class GeofenceEventQueue {
    static let shared = GeofenceEventQueue(delayBetweenTasks: 0.25)

    private let stateQueue = DispatchQueue(label: "\(Constants.PACKAGE_NAME).geofenceEventQueue.state")
    private var pendingTasks: [(@escaping () -> Void) -> Void] = []
    private var isRunning: Bool = false
    private let delayBetweenTasks: TimeInterval

    init(delayBetweenTasks: TimeInterval) {
        self.delayBetweenTasks = delayBetweenTasks
    }

    /// Enqueue a unit of work. The provided closure receives a `done` callback
    /// that MUST be invoked when the work has completed so the queue can
    /// schedule the next task after the configured delay.
    func enqueue(_ task: @escaping (@escaping () -> Void) -> Void) {
        stateQueue.async {
            self.pendingTasks.append(task)
            self.startNextIfNeeded()
        }
    }

    private func startNextIfNeeded() {
        guard !isRunning, !pendingTasks.isEmpty else { return }
        isRunning = true
        let nextTask = pendingTasks.removeFirst()

        // Execute work on the main thread because Flutter engine interactions
        // and plugin registration typically expect main-thread affinity.
        DispatchQueue.main.async {
            nextTask { [weak self] in
                self?.finishCurrentTask()
            }
        }
    }

    private func finishCurrentTask() {
        stateQueue.asyncAfter(deadline: .now() + delayBetweenTasks) {
            self.isRunning = false
            self.startNextIfNeeded()
        }
    }
}



