import Testing
@testable import Shelved

@MainActor
struct RouterTests {
    @Test func pushIncreasesDepth() {
        let router = Router()
        router.push(.itemDetail(MediaID(rawValue: "a")))
        router.push(.creator(CreatorID(rawValue: "b")))
        #expect(router.depth == 2)
    }

    @Test func popOnEmptyStackIsSafe() {
        let router = Router()
        router.pop()
        #expect(router.depth == 0)
    }

    @Test func popToRootClearsStack() {
        let router = Router()
        router.setStack([
            .itemDetail(MediaID(rawValue: "a")),
            .creator(CreatorID(rawValue: "b")),
            .itemDetail(MediaID(rawValue: "c")),
        ])
        router.popToRoot()
        #expect(router.depth == 0)
    }
}

@MainActor
struct TabCoordinatorTests {
    @Test func reTappingSelectedTabPopsToRoot() {
        let coordinator = TabCoordinator()
        coordinator.select(.search)
        coordinator.router(for: .search).push(.itemDetail(MediaID(rawValue: "a")))

        coordinator.select(.search)

        #expect(coordinator.router(for: .search).depth == 0)
    }

    @Test func switchingTabsKeepsEachStack() {
        let coordinator = TabCoordinator()
        coordinator.select(.search)
        coordinator.router(for: .search).push(.itemDetail(MediaID(rawValue: "a")))

        coordinator.select(.library)
        coordinator.select(.search)

        #expect(coordinator.router(for: .search).depth == 1)
    }
}
