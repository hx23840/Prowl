import Foundation

nonisolated struct PersistedRepositoryEntry: Codable, Equatable, Sendable {
  let path: String
  let kind: Repository.Kind

  nonisolated init(path: String, kind: Repository.Kind) {
    self.path = path
    self.kind = kind
  }
}
