import Foundation

enum ShizukuStartScript {

    static let package = "moe.shizuku.privileged.api"

    static let abis = ["arm64", "arm64-v8a", "x86_64", "armeabi-v7a", "arm", "x86"]

    static let legacyPath =
        "/storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh"

    static let notInstalledMarker = "synco-status: not-installed"

    static let noStarterMarker = "synco-status: no-starter"

    static let successMarker = "exit with 0"

    static var shell: String {
        """
        p=$(pm path \(package) 2>/dev/null | head -n 1)
        p=${p#package:}
        if [ -z "$p" ]; then echo "\(notInstalledMarker)"; exit 1; fi
        d=${p%/*}
        for a in \(abis.joined(separator: " ")); do
          s="$d/lib/$a/libshizuku.so"
          if [ -f "$s" ]; then exec "$s"; fi
        done
        if [ -f "\(legacyPath)" ]; then exec sh "\(legacyPath)"; fi
        echo "\(noStarterMarker)"
        exit 1
        """
    }
}
