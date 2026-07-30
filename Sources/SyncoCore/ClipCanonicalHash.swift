import CryptoKit
import Foundation

public enum ClipCanonicalHash {
    public static func canonicalBytes(for representations: [ClipRepresentation]) -> Data {
        var output = Data()
        for representation in representations {
            output.append(contentsOf: representation.kind.rawValue.utf8)
            output.append(SyncoConstants.Canonical.unitSeparator)
            output.append(bytes(for: representation))
            output.append(SyncoConstants.Canonical.recordSeparator)
        }
        return output
    }

    public static func hexDigest(for representations: [ClipRepresentation]) -> String {
        let digest = SHA256.hash(data: canonicalBytes(for: representations))
        return HexEncoding.encode(Data(digest))
    }

    private static func bytes(for representation: ClipRepresentation) -> Data {
        switch representation {
        case .text(let value):
            return escaped(Data(value.utf8))
        case .html(let value):
            return escaped(Data(value.utf8))
        case .rtf(let value):
            return escaped(value)
        case .url(let value):
            return escaped(Data(value.url.utf8))
        case .image(let value):
            return escaped(Data(value.sha256.utf8))
        case .file(let value):
            var output = escaped(Data(value.name.utf8))
            output.append(SyncoConstants.Canonical.unitSeparator)
            output.append(escaped(Data(value.sha256.utf8)))
            return output
        }
    }

    private static func escaped(_ value: Data) -> Data {
        var output = Data(capacity: value.count)
        for byte in value {
            if byte == SyncoConstants.Canonical.escape
                || byte == SyncoConstants.Canonical.unitSeparator
                || byte == SyncoConstants.Canonical.recordSeparator {
                output.append(SyncoConstants.Canonical.escape)
            }
            output.append(byte)
        }
        return output
    }
}
