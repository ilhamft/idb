import idb/internals/internal.{type Key}

/// Type to represent a [key range](https://developer.mozilla.org/docs/Web/API/IDBKeyRange)
/// used to query on an IndexedDB object store or index.
/// 
pub type KeyRange

/// Creates a `KeyRange` that contains all value.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeAll")
pub fn all() -> KeyRange

/// Creates a `KeyRange` with only a single `Key`.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeOnly")
pub fn only(key: Key) -> KeyRange

/// Creates a `KeyRange` with only a lower bound.
/// The lower endpoint value is included in the range.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeLowerBound")
pub fn lower_bound(key: Key) -> KeyRange

/// Creates a `KeyRange` with only a lower bound.
/// The lower endpoint value is excluded from the range.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeExclusiveLowerBound")
pub fn exclusive_lower_bound(key: Key) -> KeyRange

/// Creates a `KeyRange` with only an upper bound.
/// The upper endpoint value is included in the range.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeUpperBound")
pub fn upper_bound(key: Key) -> KeyRange

/// Creates a `KeyRange` with only an upper bound.
/// The upper endpoint value is excluded from the range.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeExclusiveUpperBound")
pub fn exclusive_upper_bound(key: Key) -> KeyRange

/// Creates a `KeyRange` with both lower and upper bound.
/// The third and fourth argument determines whether or not 
/// the lower and upper endpoint value is excluded from the range 
/// respectively.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeBound")
pub fn bound(
  lower: Key,
  upper: Key,
  exclude_lower_endpoint: Bool,
  exclude_upper_endpoint: Bool,
) -> KeyRange

/// Determines whether or not a `Key` is inside a `KeyRange`.
/// 
@external(javascript, "../idb_ffi.ts", "keyRangeIncludes")
pub fn is_in_range(key: Key, of range: KeyRange) -> Bool
