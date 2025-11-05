/// Type to represent the type of [key](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key)
/// used on an IndexedDB [object store](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#object_store).
/// 
pub type ObjectStoreKey {
  /// [Out-of-line](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#out-of-line_key) 
  /// key.
  /// 
  /// If an [object store](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#object_store)
  /// is created using this type of key, 
  /// then a key must be provided for all insert operation.
  /// 
  OutOfLineKey

  /// Auto incremented [out-of-line](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#out-of-line_key) 
  /// key.
  /// 
  AutoIncrementedOutOfLineKey

  /// [In-line](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#in-line_key) 
  /// key, with the specified [key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path).
  /// 
  /// If empty string, then it will be treated as `OutOfLineKey`.
  /// 
  InLineKey(String)

  /// Auto incremented [in-line](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#in-line_key) 
  /// key, with the specified [key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path).
  /// 
  /// If empty string, then it will be treated as `AutoIncrementedOutOfLineKey`.
  /// 
  AutoIncrementedInLineKey(String)

  /// Compound [in-line](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#in-line_key) 
  /// key, with the specified [key paths](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path).
  /// 
  /// Empty string will be ignored.
  /// If empty list, then it will be treated as `OutOfLineKey`.
  /// 
  CompoundInLineKey(List(String))
}
