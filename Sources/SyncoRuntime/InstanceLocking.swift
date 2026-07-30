public protocol InstanceLocking: AnyObject {
    func acquire() -> InstanceLockOutcome
    func release()
}
