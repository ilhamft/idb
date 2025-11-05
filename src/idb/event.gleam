import idb/internals/internal.{type Transaction}

/// Type to represent event handlers of the [`connect`](#connect) function.
/// 
/// Use [`on_upgrade`](#on_upgrade), [`on_blocked`](#on_blocked),
/// [`on_blocking`](#on_blocking), or [`on_terminated`](#on_terminated)
/// to create an instance of `ConnectEventHandler`.
/// 
pub type ConnectEventHandler(a, b, c, d) {
  /// Handles database version upgrade.
  /// 
  /// The handler is executed when an attempt was made to connect to a database 
  /// with a version number higher than its current version.
  /// When the opened database doesn't exist yet, its current version is 0.
  /// 
  /// A `versionchange` transaction, the current version, and the new version
  /// of the database will be provided to the handler. 
  /// The returned value is discarded.
  /// 
  /// Similar to the [`IDBOpenDBRequest.onupgradeneeded`](https://developer.mozilla.org/docs/Web/API/IDBOpenDBRequest/upgradeneeded_event)
  /// on the IndexedDB API.
  /// 
  OnUpgrade(fn(Transaction, Int, Int) -> a)

  /// Handles blocked database version upgrade.
  /// 
  /// The handler is executed when an attempt was blocked to connect to a database 
  /// with a version number higher than its current version.
  /// 
  /// The current version and the new version of the database 
  /// will be provided to the handler.
  /// The returned value is discarded.
  /// 
  /// Similar to the [`IDBOpenDBRequest.onblocked`](https://developer.mozilla.org/docs/Web/API/IDBOpenDBRequest/blocked_event)
  /// on the IndexedDB API.
  /// 
  OnBlocked(fn(Int, Int) -> b)

  /// Handles database version upgrade request.
  /// 
  /// The handler is executed when this connection is blocking an attempt to connect
  /// to this database with a version number higher than its current version.
  /// 
  /// The current version and the blocked version of the database 
  /// will be provided to the handler.
  /// The returned value is discarded.
  /// 
  /// Similar to the [`IDBDatabase.onversionchange`](https://developer.mozilla.org/docs/Web/API/IDBDatabase/versionchange_event)
  /// on the IndexedDB API.
  /// 
  OnBlocking(fn(Int, Int) -> c)

  /// Handles unexpected connection termination.
  /// 
  /// The returned value is discarded.
  /// 
  /// Similar to the [`IDBDatabase.onclose`](https://developer.mozilla.org/docs/Web/API/IDBDatabase/close_event)
  /// on the IndexedDB API.
  /// 
  OnTerminated(fn() -> d)
}
