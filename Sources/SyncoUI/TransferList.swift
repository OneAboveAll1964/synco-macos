import SwiftUI
import SyncoCore
import SyncoTransfer

@MainActor
struct TransferList: View {
    let transfers: [TransferProgress]
    let onCancel: (TransferID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "Transfers")
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    ForEach(transfers) { transfer in
                        TransferRow(transfer: transfer) {
                            onCancel(transfer.transferID)
                        }
                    }
                }
            }
            .scrollIndicators(.never)
            .frame(maxHeight: Theme.Size.transferListMaxHeight)
        }
    }
}
