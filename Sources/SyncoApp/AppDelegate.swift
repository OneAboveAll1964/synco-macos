import AppKit
import SyncoCore
import SyncoRuntime
import SyncoSync
import SyncoTransfer
import SyncoUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let instanceGuard = SingleInstanceGuard()
    private var graph: SyncoGraph?
    private var viewModel: AppViewModel?
    private var menuBar: MenuBarController?
    private var launchTask: Task<Void, Never>?
    private var isTerminating = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        let admission = instanceGuard.admit()
        if let notice = admission.notice {
            StartupConsole.emit(notice)
        }
        guard admission.allowsLaunch else { exit(EXIT_FAILURE) }
        if let notice = BundleEnvironment.current.startupNotice {
            StartupConsole.emit(notice)
        }
        TerminationSignalWatch.install { number in
            StartupConsole.emit(
                "signal \(number): withdrawing the Bonjour advertisement and stopping the listener"
            )
            NSApp.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        launchTask = Task { await self.launch() }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        instanceGuard.relinquish()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isTerminating else { return .terminateLater }
        isTerminating = true
        let pendingLaunch = launchTask
        Task {
            await pendingLaunch?.value
            await self.shutDown()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    private func shutDown() async {
        guard let graph else { return }
        await graph.commands.stop()
        viewModel?.end()
        menuBar?.teardown()
        StartupConsole.emit("synco stopped: advertisement withdrawn, listener closed")
    }

    private func launch() async {
        do {
            let paths = TransferPaths.shared
            let graph = try await SyncoGraph.make(paths: paths)
            let viewModel = await AppViewModel.make(graph: graph, paths: paths)
            let menuBar = MenuBarController(viewModel: viewModel)
            viewModel.begin()
            menuBar.install()
            self.graph = graph
            self.viewModel = viewModel
            self.menuBar = menuBar
            await graph.commands.start()
            SyncoLog.app.info(
                "synco running as \(graph.identity.deviceID.rawValue, privacy: .public)"
            )
        } catch {
            SyncoLog.app.error(
                "synco could not start: \(String(describing: error), privacy: .public)"
            )
            LaunchFailureAlert.present(error)
        }
    }
}
