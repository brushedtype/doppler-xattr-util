import Foundation
import Cocoa
import DopplerExtendedAttributes

func printHelp() {
    let helpText = """
    CLI util to quickly access/edit the Doppler xattr for files.

    Usage:

      doppler-xattr-util mark-changed <path to file>

      doppler-xattr-util clear <path to file>

      doppler-xattr-util is-changed <path to file>

      doppler-xattr-util send-event <path to application>
    """
    print(helpText)
}

func markChanged(_ pathToFile: String) throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileURL = URL(fileURLWithPath: pathToFile, relativeTo: cwd).standardizedFileURL
    try setDopplerMetadataChangedAttribute(for: fileURL)
}

func clearAttr(_ pathToFile: String) throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileURL = URL(fileURLWithPath: pathToFile, relativeTo: cwd).standardizedFileURL
    try clearDopplerMetadataChangedAttribute(for: fileURL)
}

func checkIsChanged(_ pathToFile: String) throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileURL = URL(fileURLWithPath: pathToFile, relativeTo: cwd).standardizedFileURL

    let isChanged = try isDopplerMetadataChangedAttributeSet(for: fileURL)

    if isChanged {
        print("file is marked as having changed metadata")
    } else {
        print("file is NOT marked as having changed metadata")
    }
}

@available(macOS 10.15, *)
func sendAppleEvent(_ pathToApplication: String) async throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let applicationURL = URL(fileURLWithPath: pathToApplication, relativeTo: cwd).standardizedFileURL

    let appleEvent = NSAppleEventDescriptor(
        eventClass: DopplerEventClass,
        eventID: DopplerEditMetadataEventId,
        targetDescriptor: nil,
        returnID: AEReturnID(kAutoGenerateReturnID),
        transactionID: AETransactionID(kAnyTransactionID)
    )

    let launchConfig = NSWorkspace.OpenConfiguration()
    launchConfig.activates = true
    launchConfig.allowsRunningApplicationSubstitution = true
    launchConfig.addsToRecentItems = false
    launchConfig.appleEvent = appleEvent

    _ = try await NSWorkspace.shared.open([], withApplicationAt: applicationURL, configuration: launchConfig)
}

enum Error: Swift.Error {
    case unknownCommand
    case missingCommand
    case missingArgument(String)
    case unsupportedOS(String)
}

func runMain() async throws {
    var args = CommandLine.arguments.dropFirst()

    guard args.count >= 1 else {
        throw Error.missingCommand
    }

    let command = args.removeFirst()

    switch command {
    case "help":
        printHelp()

    case "mark-changed":
        guard let pathToFile = args.first else {
            throw Error.missingArgument("<path to file>")
        }
        try markChanged(pathToFile)

    case "clear":
        guard let pathToFile = args.first else {
            throw Error.missingArgument("<path to file>")
        }
        try clearAttr(pathToFile)

    case "is-changed":
        guard let pathToFile = args.first else {
            throw Error.missingArgument("<path to file>")
        }
        try checkIsChanged(pathToFile)

    case "send-event":
        guard let pathToApp = args.first else {
            throw Error.missingArgument("<path to app>")
        }

        guard #available(macOS 10.15, *) else {
            throw Error.unsupportedOS("this command requires macOS 10.15 or later")
        }

        try await sendAppleEvent(pathToApp)

    default:
        throw Error.unknownCommand
    }

    exit(EXIT_SUCCESS)
}

_runAsyncMain {
    do {
        try await runMain()

    } catch let err as Error {
        switch err {
        case .missingArgument(let arg):
            print("error: missing \(arg)")

        case .missingCommand:
            print("error: missing command")

        case .unknownCommand:
            print("error: unknown command")

        case .unsupportedOS(let message):
            print("error: \(message)")
        }

        print("")
        printHelp()
        exit(EXIT_FAILURE)

    } catch let err {
        print("error: \((err as NSError).localizedDescription)")
        print("")
        printHelp()
        exit(EXIT_FAILURE)
    }
}
