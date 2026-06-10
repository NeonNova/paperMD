import Foundation

/// Watches a single directory for filesystem changes using a `DispatchSource`,
/// coalescing bursts of events into one callback. Used both for the open
/// document's directory (external-edit detection) and for sidebar tree refresh.
public final class FolderWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var coalesceWorkItem: DispatchWorkItem?

    public init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    public func start() {
        stop()
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: .main)
        src.setEventHandler { [weak self] in self?.coalesce() }
        src.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        source = src
        src.resume()
    }

    /// Debounces a burst of events into a single 300 ms-delayed callback.
    private func coalesce() {
        coalesceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        coalesceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    public func stop() {
        coalesceWorkItem?.cancel()
        source?.cancel()
        source = nil
    }

    deinit { stop() }
}
