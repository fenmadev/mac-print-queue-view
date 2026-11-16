// Phase 01 evidence E04 clean-up: removes exactly the given test jobs (by job ID) from the
// completed-job history with the app's CUPSClient.purgeJob. Usage: purge <printer> <id>...
let arguments = CommandLine.arguments
for id in arguments.dropFirst(2).compactMap({ Int32($0) }) {
    do { try CUPSClient.purgeJob(id: id, printer: arguments[1]); print("purged \(id)") } catch { print("purge \(id): \(error)") }
}
