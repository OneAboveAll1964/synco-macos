import SwiftUI
import SyncoSync

@MainActor
public struct StatusPanel: View {
    let viewModel: AppViewModel
    let openSettings: () -> Void
    let pairByQR: () -> Void
    let quit: () -> Void

    public init(
        viewModel: AppViewModel,
        openSettings: @escaping () -> Void,
        pairByQR: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.openSettings = openSettings
        self.pairByQR = pairByQR
        self.quit = quit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            StatusPanelHeader(identity: viewModel.state.identity, summary: viewModel.summary)
            if let problem = viewModel.state.problem {
                ProblemBanner(problem: problem)
            }
            DirectionControl(selection: viewModel.directionChoice) { choice in
                viewModel.setDirectionChoice(choice)
            }
            Divider()
            PeerListSection(viewModel: viewModel)
            if !viewModel.state.transfers.isEmpty {
                Divider()
                TransferList(transfers: viewModel.state.transfers) { transferID in
                    viewModel.cancelTransfer(transferID)
                }
            }
            Divider()
            StatusPanelFooter(openSettings: openSettings, pairByQR: pairByQR, quit: quit)
        }
        .padding(Theme.Spacing.large)
        .frame(width: Theme.Size.popoverWidth)
    }
}
