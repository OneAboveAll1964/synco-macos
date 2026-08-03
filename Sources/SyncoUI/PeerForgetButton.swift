import SwiftUI
import SyncoSync

@MainActor
struct PeerForgetButton: View {
    let peer: PeerSnapshot
    let viewModel: AppViewModel

    @State private var isConfirming = false

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Button("Forget", role: .destructive) { isConfirming = true }
                .controlSize(.small)
        }
        .confirmationDialog(
            "Forget \(peer.displayName)?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Forget", role: .destructive) { viewModel.forget(peer.deviceID) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This Mac will stop syncing with it until you pair the two again.")
        }
    }
}
