/// Type to represent the type of [key](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key)
/// used on an IndexedDB [index](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#index).
/// 
pub type IndexKey {
  /// [Key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path) 
  /// for the index.
  /// 
  Key(String)

  /// Compound [key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path) 
  /// for the index.
  /// 
  /// Empty string will be ignored.
  /// If empty list, then it will be treated as `Key` with empty string.
  /// 
  CompoundKey(List(String))

  /// [Key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path) 
  /// for the index with [unique](https://developer.mozilla.org/docs/Web/API/IDBIndex/unique) property.
  /// 
  UniqueKey(String)

  /// Compound [key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path) 
  /// for the index with [unique](https://developer.mozilla.org/docs/Web/API/IDBIndex/unique) property.
  /// 
  /// Empty string will be ignored.
  /// If empty list, then it will be treated as `UniqueKey` with empty string.
  /// 
  UniqueCompoundKey(List(String))

  /// [Key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path) 
  /// for the index with [multi entry](https://developer.mozilla.org/docs/Web/API/IDBIndex/multiEntry) 
  /// property.
  /// 
  MultiEntryKey(String)

  /// [Key path](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key_path) 
  /// for the index with [multi entry](https://developer.mozilla.org/docs/Web/API/IDBIndex/multiEntry) 
  /// and [unique](https://developer.mozilla.org/docs/Web/API/IDBIndex/unique) 
  /// property.
  /// 
  MultiEntryUniqueKey(String)
}
