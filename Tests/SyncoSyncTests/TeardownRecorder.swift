actor TeardownRecorder {
    private var steps: [TeardownStep] = []

    func record(_ step: TeardownStep) {
        steps.append(step)
    }

    func recordedSteps() -> [TeardownStep] {
        steps
    }
}
