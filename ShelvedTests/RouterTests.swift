import Testing
@testable import Shelved

@MainActor
struct RouterTests {
    @Test func pushIncreasesDepth() {
        let router = Router()
        router.push(.itemDetail(.openLibraryWork("a")))
        router.push(.creator(.openLibraryAuthor("b")))
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
            .itemDetail(.openLibraryWork("a")),
            .creator(.openLibraryAuthor("b")),
            .itemDetail(.openLibraryWork("c")),
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
        coordinator.router(for: .search).push(.itemDetail(.openLibraryWork("a")))

        coordinator.select(.search)

        #expect(coordinator.router(for: .search).depth == 0)
    }

    @Test func switchingTabsKeepsEachStack() {
        let coordinator = TabCoordinator()
        coordinator.select(.search)
        coordinator.router(for: .search).push(.itemDetail(.openLibraryWork("a")))

        coordinator.select(.library)
        coordinator.select(.search)

        #expect(coordinator.router(for: .search).depth == 1)
    }
}
