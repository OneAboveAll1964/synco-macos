import SwiftUI
import SyncoCore
import SyncoSettings
import SyncoSync

@MainActor
struct PeerPolicyDisclosure: View {
    let peer: PeerSnapshot
    let viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Picker("Direction", selection: directionBinding) {
                ForEach(SyncDirection.allCases) { direction in
                    Text(direction.title).tag(direction)
                }
            }
            .pickerStyle(.menu)
            .font(Theme.Typography.body)
            TypeToggleRow(
                title: "Send to \(peer.displayName)",
                flags: peer.policy.send,
                isEnabled: !viewModel.document.paused
            ) { category, enabled in
                viewModel.setSending(enabled, of: category, for: peer.deviceID)
            }
            TypeToggleRow(
                title: "Receive from \(peer.displayName)",
                flags: peer.policy.receive,
                isEnabled: !viewModel.document.paused
            ) { category, enabled in
                viewModel.setReceiving(enabled, of: category, for: peer.deviceID)
            }
            if let capabilities = peer.peerCapabilities {
                Text("That device accepts \(CapabilityList.string(capabilities.accepts)) and sends \(CapabilityList.string(capabilities.sends)).")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let fingerprint = peer.fingerprint {
                Text(fingerprint.grouped)
                    .font(Theme.Typography.fingerprintCompact)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            PeerForgetButton(peer: peer, viewModel: viewModel)
        }
    }

    private var directionBinding: Binding<SyncDirection> {
        Binding(
            get: { SyncDirection(policy: peer.policy) },
            set: { viewModel.setDirection($0, for: peer.deviceID) }
        )
    }
}
