import Darwin
import Foundation

@main
struct SoundPlaybackQueueCheck {

    static func main() {
        idleQueueStartsRequestedEffect()
        playingQueueDefersNextEffect()
        finishingCurrentEffectStartsQueuedEffect()
        print("SoundPlaybackQueue checks passed")
    }

    private static func idleQueueStartsRequestedEffect() {
        var queue = SoundPlaybackQueue()

        let nextEffect = queue.request(.basic)

        require(nextEffect == .basic, "idle queue should start requested effect immediately")
        require(queue.currentEffect == .basic, "current effect should be tracked")
        require(queue.queuedEffectCount == 0, "idle request should not leave pending effects")
    }

    private static func playingQueueDefersNextEffect() {
        var queue = SoundPlaybackQueue()

        let firstEffect = queue.request(.basic)
        let deferredEffect = queue.request(.enhanced)

        require(firstEffect == .basic, "first request should start immediately")
        require(deferredEffect == nil, "second request should wait for current playback")
        require(queue.currentEffect == .basic, "current effect should not be interrupted")
        require(queue.queuedEffectCount == 1, "deferred effect should be queued")
    }

    private static func finishingCurrentEffectStartsQueuedEffect() {
        var queue = SoundPlaybackQueue()
        _ = queue.request(.basic)
        _ = queue.request(.enhanced)

        let nextEffect = queue.finishCurrent()
        let finalEffect = queue.finishCurrent()

        require(nextEffect == .enhanced, "queued effect should start after current finishes")
        require(finalEffect == nil, "queue should be idle after last effect finishes")
        require(queue.currentEffect == nil, "current effect should clear when queue drains")
        require(queue.queuedEffectCount == 0, "pending effects should be drained")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }
}
