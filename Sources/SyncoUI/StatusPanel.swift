import SwiftUI
import SyncoSync

@MainActor
public struct StatusPanel: View {
    let viewModel: AppViewModel
    let actions: StatusPanelActions

    public init(viewModel: AppViewModel, actions: StatusPanelActions) {
        self.viewModel = viewModel
        self.actions = actions
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
            ActionRow(actions: actions)
            Divider()
            PeerListSection(viewModel: viewModel)
            if !viewModel.clips.isEmpty {
                Divider()
                RecentClipsSection(clips: viewModel.clips)
            }
            if !viewModel.state.transfers.isEmpty {
                Divider()
                TransferList(transfers: viewModel.state.transfers) { transferID in
                    viewModel.cancelTransfer(transferID)
                }
            }
            Divider()
            StatusPanelFooter(openSettings: actions.openSettings, quit: actions.quit)
        }
        .padding(Theme.Spacing.large)
        .frame(width: Theme.Size.popoverWidth)
    }
}
