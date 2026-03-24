import ComposableArchitecture
import DependenciesTestSupport
import Foundation
import Sharing
import Testing

@testable import supacode

@MainActor
struct RepositorySettingsFeatureTests {
  @Test(.dependencies) func plainFolderTaskLoadsWithoutGitRequests() async {
    let rootURL = URL(fileURLWithPath: "/tmp/folder-\(UUID().uuidString)")
    let settingsStorage = SettingsTestStorage()
    let localStorage = RepositoryLocalSettingsTestStorage()
    let settingsFileURL = URL(fileURLWithPath: "/tmp/supacode-settings-\(UUID().uuidString).json")
    let storedSettings = RepositorySettings(
      setupScript: "echo setup",
      archiveScript: "echo archive",
      runScript: "npm run dev",
      openActionID: OpenWorktreeAction.automaticSettingsID,
      worktreeBaseRef: "origin/main",
      copyIgnoredOnWorktreeCreate: true,
      copyUntrackedOnWorktreeCreate: true,
      pullRequestMergeStrategy: .squash
    )
    let storedOnevcatSettings = OnevcatRepositorySettings(
      customCommands: [.default(index: 0)]
    )
    let bareRepositoryRequests = LockIsolated(0)
    let branchRefRequests = LockIsolated(0)
    let automaticBaseRefRequests = LockIsolated(0)
    withDependencies {
      $0.settingsFileStorage = settingsStorage.storage
      $0.settingsFileURL = settingsFileURL
      $0.repositoryLocalSettingsStorage = localStorage.storage
    } operation: {
      @Shared(.repositorySettings(rootURL)) var repositorySettings
      @Shared(.onevcatRepositorySettings(rootURL)) var onevcatRepositorySettings
      @Shared(.settingsFile) var settingsFile
      $repositorySettings.withLock { $0 = storedSettings }
      $onevcatRepositorySettings.withLock { $0 = storedOnevcatSettings }
      $settingsFile.withLock { $0.global.defaultWorktreeBaseDirectoryPath = "/tmp/worktrees" }
    }

    let store = TestStore(
      initialState: RepositorySettingsFeature.State(
        rootURL: rootURL,
        repositoryKind: .plain,
        settings: .default,
        onevcatSettings: .default
      )
    ) {
      RepositorySettingsFeature()
    } withDependencies: {
      $0.settingsFileStorage = settingsStorage.storage
      $0.settingsFileURL = settingsFileURL
      $0.repositoryLocalSettingsStorage = localStorage.storage
      $0.gitClient.isBareRepository = { _ in
        bareRepositoryRequests.withValue { $0 += 1 }
        return false
      }
      $0.gitClient.branchRefs = { _ in
        branchRefRequests.withValue { $0 += 1 }
        return []
      }
      $0.gitClient.automaticWorktreeBaseRef = { _ in
        automaticBaseRefRequests.withValue { $0 += 1 }
        return "origin/main"
      }
    }
    store.exhaustivity = .off

    await store.send(.task)
    await store.finish()

    #expect(store.state.settings == storedSettings)
    #expect(store.state.onevcatSettings == storedOnevcatSettings)
    #expect(store.state.globalDefaultWorktreeBaseDirectoryPath == "/tmp/worktrees")
    #expect(store.state.isBranchDataLoaded == false)
    #expect(store.state.branchOptions.isEmpty)
    #expect(bareRepositoryRequests.value == 0)
    #expect(branchRefRequests.value == 0)
    #expect(automaticBaseRefRequests.value == 0)
  }

  @Test func plainFolderVisibilityHidesGitOnlySections() {
    let state = RepositorySettingsFeature.State(
      rootURL: URL(fileURLWithPath: "/tmp/folder"),
      repositoryKind: .plain,
      settings: .default,
      onevcatSettings: .default
    )

    #expect(state.showsWorktreeSettings == false)
    #expect(state.showsPullRequestSettings == false)
    #expect(state.showsSetupScriptSettings == false)
    #expect(state.showsArchiveScriptSettings == false)
    #expect(state.showsRunScriptSettings == true)
    #expect(state.showsCustomCommandsSettings == true)
  }
}
