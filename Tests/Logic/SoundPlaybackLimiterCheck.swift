import Darwin
import Foundation

@main
struct SoundPlaybackLimiterCheck {

    static func main() {
        idleLimiterStartsRequestedEffect()
        playingLimiterDropsRapidRequests()
        restIntervalBlocksNextEffectUntilFinished()
        print("SoundPlaybackLimiter checks passed")
    }

    private static func idleLimiterStartsRequestedEffect() {
        var limiter = SoundPlaybackLimiter(restInterval: 0.25)

        let nextEffect = limiter.request(.basic)

        require(nextEffect == .basic, "idle limiter should start requested effect immediately")
        require(limiter.currentEffect == .basic, "current effect should be tracked")
        require(limiter.isPlaying, "limiter should track active playback")
        require(!limiter.isResting, "limiter should not rest while playback is active")
    }

    private static func playingLimiterDropsRapidRequests() {
        var limiter = SoundPlaybackLimiter(restInterval: 0.25)

        let firstEffect = limiter.request(.basic)
        let droppedEnhanced = limiter.request(.enhanced)
        let droppedBasic = limiter.request(.basic)

        require(firstEffect == .basic, "first request should start immediately")
        require(droppedEnhanced == nil, "request during playback should be dropped")
        require(droppedBasic == nil, "extra rapid request should also be dropped")
        require(limiter.currentEffect == .basic, "current effect should not be interrupted")
    }

    private static func restIntervalBlocksNextEffectUntilFinished() {
        var limiter = SoundPlaybackLimiter(restInterval: 0.25)
        _ = limiter.request(.basic)

        let restInterval = limiter.finishCurrent()
        let blockedEffect = limiter.request(.enhanced)
        limiter.finishRest()
        let nextEffect = limiter.request(.enhanced)

        require(restInterval == 0.25, "finishing playback should start a rest interval")
        require(blockedEffect == nil, "request during rest should be dropped")
        require(nextEffect == .enhanced, "request after rest should start")
        require(limiter.currentEffect == .enhanced, "new effect should be tracked after rest")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }
}
