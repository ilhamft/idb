import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import idb/event.{type ConnectEventHandler}
import idb/index.{type IndexKey}
import idb/internals/internal
import idb/range.{type KeyRange}
import idb/store.{type ObjectStoreKey}

// ---- Types -----------------------------------------------------------------

/// Type to represent a [connection](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#database_connection)
/// to an IndexedDB [database](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#database).
/// 
/// Use [`connect`](#connect) to create an instance of `Connection`.
/// 
pub type Connection

/// Type to represent an IndexedDB error.
/// 
pub type IdbError

/// Type to represent an IndexedDB [index](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#index).
/// 
/// Use [`create_index`](#create_index) to create an instance of `Index`.
/// 
pub type Index

/// Type to represent the [key](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#key)
/// used on an IndexedDB object store or index.
/// 
pub type Key =
  internal.Key

/// Type to represent an IndexedDB [object store](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#object_store).
/// 
/// Use [`create_store`](#create_store) to create an instance of `ObjectStore`.
/// 
pub type ObjectStore

/// Type to represent an IndexedDB [transaction](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#transaction).
/// 
/// Use [`start_transaction`](#start_transaction) to create an instance of `Transaction`.
/// 
pub type Transaction =
  internal.Transaction

/// Type to represent an IndexedDB [transaction](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#transaction) 
/// access [mode](https://developer.mozilla.org/docs/Web/API/IDBTransaction/mode).
/// 
pub type TransactionMode {
  ReadOnly
  ReadWrite
}

// ---- Key  Constructors -----------------------------------------------------

/// Creates a new `Key` from `String`.
/// 
@external(javascript, "./idb_ffi.ts", "key")
pub fn key_string(value: String) -> Key

/// Creates a new `Key` from `Int`.
/// 
@external(javascript, "./idb_ffi.ts", "key")
pub fn key_int(value: Int) -> Key

/// Creates a new `Key` from `Float`.
/// 
@external(javascript, "./idb_ffi.ts", "key")
pub fn key_float(value: Float) -> Key

/// Creates a new `Key` from a list of `Key`.
/// 
@external(javascript, "./idb_ffi.ts", "key")
pub fn key_list(value: List(Key)) -> Key

// ---- Database Functions ----------------------------------------------------

/// Retrieves a list of available databases, returning its name and version.
/// 
/// The last argument is executed when the list is available 
/// or when the attempt is failed.
/// 
@external(javascript, "./idb_ffi.ts", "getDatabases")
pub fn get_databases(
  next: fn(Result(List(#(String, Int)), IdbError)) -> a,
) -> Nil

/// Creates a connection to an IndexedDB database with the specified name and version.
/// 
/// If the specified version is zero or negative value, then it will be treated as 1.
/// 
/// If the database does not exist, then it will be created.
/// 
/// The last argument is executed when the connection is created 
/// or when the attempt is failed.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBFactory.open`](https://developer.mozilla.org/docs/Web/API/IDBFactory/open)
/// on the IndexedDB API.
/// 
pub fn connect(
  name: String,
  version: Int,
  event_handlers: List(ConnectEventHandler(a, b, c, d)),
  next: fn(Result(Connection, IdbError)) -> e,
) -> Nil {
  let #(on_upgrade_needed, on_blocked, on_version_change, on_close) = {
    event_handlers
    |> list.fold(#(None, None, None, None), fn(acc, handler) {
      case handler {
        event.OnUpgrade(x) -> #(Some(x), acc.1, acc.2, acc.3)
        event.OnBlocked(x) -> #(acc.0, Some(x), acc.2, acc.3)
        event.OnBlocking(x) -> #(acc.0, acc.1, Some(x), acc.3)
        event.OnTerminated(x) -> #(acc.0, acc.1, acc.2, Some(x))
      }
    })
  }

  do_connect(
    name,
    case version {
      v if v <= 0 -> 1
      v -> v
    },
    on_upgrade_needed,
    on_blocked,
    on_version_change,
    on_close,
    next,
  )
}

@external(javascript, "./idb_ffi.ts", "connect")
fn do_connect(
  name: String,
  version: Int,
  on_upgrade_needed: Option(fn(Transaction, Int, Int) -> a),
  on_blocked: Option(fn(Int, Int) -> b),
  on_version_change: Option(fn(Int, Int) -> c),
  on_close: Option(fn() -> d),
  next: fn(Result(Connection, IdbError)) -> e,
) -> Nil

/// This is an utility function that combines
/// [`connect`](#connect) with `result.try`.
/// 
pub fn try_connect(
  name: String,
  version: Int,
  event_handlers: List(ConnectEventHandler(a, b, c, d)),
  apply fun: fn(Connection) -> Result(e, IdbError),
) -> Nil {
  use db <- connect(name, version, event_handlers)
  result.try(db, fun)
}

/// Deletes an IndexedDB database with the specified name.
/// 
/// The last argument is executed when the database is deleted 
/// or when the attempt is failed.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBFactory.deleteDatabase`](https://developer.mozilla.org/docs/Web/API/IDBFactory/deleteDatabase)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "deleteDatabase")
pub fn delete_database(
  name: String,
  next: fn(Result(Nil, IdbError)) -> a,
) -> Nil

/// Starts a new transaction that can be used to access the specified object stores.
/// 
/// The last argument is executed when the transaction is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBDatabase.transaction`](https://developer.mozilla.org/docs/Web/API/IDBDatabase/transaction)
/// on the IndexedDB API.
/// 
pub fn start_transaction(
  db: Connection,
  store_names: List(String),
  mode: TransactionMode,
  on_close: fn(Result(Nil, IdbError)) -> a,
) -> Result(Transaction, IdbError) {
  do_start_transaction(
    db,
    store_names,
    case mode {
      ReadOnly -> "readonly"
      ReadWrite -> "readwrite"
    },
    on_close,
  )
}

@external(javascript, "./idb_ffi.ts", "startTransaction")
fn do_start_transaction(
  db: Connection,
  store_names: List(String),
  mode: String,
  on_close: fn(Result(Nil, IdbError)) -> a,
) -> Result(Transaction, IdbError)

/// Starts a new transaction with only a single object store.
/// 
/// The last argument is executed when the transaction is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_transaction`](#start_transaction) with [`get_store`](#get_store).
/// 
pub fn start_store_transaction(
  db: Connection,
  store_name: String,
  mode: TransactionMode,
  on_close: fn(Result(Nil, IdbError)) -> a,
) -> Result(ObjectStore, IdbError) {
  use tx <- result.try(start_transaction(db, [store_name], mode, on_close))
  get_store(tx, store_name)
}

/// Starts a new transaction with only a single index.
/// 
/// The last argument is executed when the transaction is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_transaction`](#start_transaction) with [`get_store`](#get_store) 
/// and [`get_index`](#get_index).
/// 
pub fn start_index_transaction(
  db: Connection,
  store_index_name: #(String, String),
  on_close: fn(Result(Nil, IdbError)) -> a,
) -> Result(Index, IdbError) {
  use tx <- result.try(start_transaction(
    db,
    [store_index_name.0],
    ReadOnly,
    on_close,
  ))
  use store <- result.try(get_store(tx, store_index_name.0))
  get_index(store, store_index_name.1)
}

// ---- ObjectStore Functions -------------------------------------------------

/// Retrieves a list of the names of the object stores 
/// currently in the connected database.
/// 
@external(javascript, "./idb_ffi.ts", "getStoreNames")
pub fn get_store_names(db: Connection) -> List(String)

/// Retrieves a list of the names of the object stores 
/// currently available in the transaction.
/// 
@external(javascript, "./idb_ffi.ts", "getTransactionStoreNames")
pub fn get_transaction_store_names(tx: Transaction) -> List(String)

/// Retrieves an object store to be used for operations.
/// 
@external(javascript, "./idb_ffi.ts", "getStore")
pub fn get_store(tx: Transaction, name: String) -> Result(ObjectStore, IdbError)

/// Creates a new object store with the specified name and key.
/// 
/// Can only be called using `versionchange` transaction, will return an `Error` otherwise.
/// Use [`connect`](#connect) with [`on_upgrade`](#on_upgrade) 
/// to initialize a `versionchange` transaction.
/// 
/// Similar to the [`IDBDatabase.createObjectStore`](https://developer.mozilla.org/docs/Web/API/IDBDatabase/createObjectStore)
/// on the IndexedDB API.
/// 
pub fn create_store(
  tx: Transaction,
  name: String,
  key: ObjectStoreKey,
) -> Result(ObjectStore, IdbError) {
  do_create_store(tx, name, case key {
    store.OutOfLineKey -> json.null()
    store.AutoIncrementedOutOfLineKey ->
      json.object([#("autoIncrement", json.bool(True))])
    store.InLineKey("") -> json.null()
    store.InLineKey(key) -> json.object([#("keyPath", json.string(key))])
    store.AutoIncrementedInLineKey("") -> json.null()
    store.AutoIncrementedInLineKey(key) ->
      json.object([
        #("keyPath", json.string(key)),
        #("autoIncrement", json.bool(True)),
      ])
    store.CompoundInLineKey([]) -> json.null()
    store.CompoundInLineKey(keys) ->
      case keys |> list.filter(fn(k) { !string.is_empty(k) }) {
        [] -> json.null()
        _ -> json.object([#("keyPath", json.array(keys, json.string))])
      }
  })
}

@external(javascript, "./idb_ffi.ts", "createStore")
fn do_create_store(
  tx: Transaction,
  name: String,
  key: Json,
) -> Result(ObjectStore, IdbError)

/// Deletes an [object store](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#object_store)
/// with the specified name, along with any indexes that reference it.
/// 
/// Can only be called using `versionchange` transaction, will return an `Error` otherwise.
/// Use [`connect`](#connect) with [`on_upgrade`](#on_upgrade) 
/// to initialize a `versionchange` transaction.
/// 
/// Similar to the [`IDBDatabase.deleteObjectStore`](https://developer.mozilla.org/docs/Web/API/IDBDatabase/deleteObjectStore)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "deleteStore")
pub fn delete_store(tx: Transaction, name: String) -> Result(Nil, IdbError)

// ---- ObjectStore Operation Functions ---------------------------------------

fn quick_operation(
  db: Connection,
  store_name: String,
  mode: TransactionMode,
  operation: fn(ObjectStore) -> Nil,
  next: fn(Result(a, IdbError)) -> b,
) -> Nil {
  {
    use store <- result.map(
      start_store_transaction(db, store_name, mode, fn(_) { Nil }),
    )
    operation(store)
  }
  |> result.map_error(fn(e) {
    next(Error(e))
    Nil
  })
  |> result_unwrap()
}

/// Inserts a new record 
/// to an object store.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.add`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/add)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "add")
pub fn add(
  store: ObjectStore,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Inserts a new record 
/// to an object store inside a new transaction.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`add`](#add).
/// 
pub fn quick_add(
  db: Connection,
  store_name: String,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { add(_, value, next) }
  |> quick_operation(db, store_name, ReadWrite, _, next)
}

/// Inserts a new record using a specified key
/// to an object store.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.add`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/add)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "addTo")
pub fn add_to(
  store: ObjectStore,
  key: Key,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Inserts a new record using a specified key 
/// to an object store inside a new transaction.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`add_to`](#add_to).
/// 
pub fn quick_add_to(
  db: Connection,
  store_name: String,
  key: Key,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { add_to(_, key, value, next) }
  |> quick_operation(db, store_name, ReadWrite, _, next)
}

/// Retrieves the total number of records within the range
/// in an object store.
/// 
/// The last argument is executed with the result or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.count`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/count)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "count")
pub fn count(
  store: ObjectStore,
  query: KeyRange,
  next: fn(Result(Int, IdbError)) -> a,
) -> Nil

/// Retrieves the total number of records within the range
/// in an object store inside a new transaction.
/// 
/// The last argument is executed with the result or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`count`](#count).
/// 
pub fn quick_count(
  db: Connection,
  store_name: String,
  query: KeyRange,
  next: fn(Result(Int, IdbError)) -> a,
) -> Nil {
  { count(_, query, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Deletes all records within the range 
/// from an object store.
/// 
/// The last argument is executed 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.delete`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/delete)
/// and [`IDBObjectStore.clear`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/clear)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "delete_")
pub fn delete(
  store: ObjectStore,
  query: KeyRange,
  next: fn(Result(Nil, IdbError)) -> a,
) -> Nil

/// Deletes all records within the range 
/// from an object store inside a new transaction.
/// 
/// The last argument is executed 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`delete`](#delete).
/// 
pub fn quick_delete(
  db: Connection,
  store_name: String,
  query: KeyRange,
  next: fn(Result(Nil, IdbError)) -> a,
) -> Nil {
  { delete(_, query, next) }
  |> quick_operation(db, store_name, ReadWrite, _, next)
}

/// Retrieves the first record within the range
/// from an object store.
/// 
/// The last argument is executed with the record value or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.get`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/get)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "getOne")
pub fn get_one(
  store: ObjectStore,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves the first record within the range
/// from an object store inside a new transaction.
/// 
/// The last argument is executed with the record value or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`get_one`](#get_one).
/// 
pub fn quick_get_one(
  db: Connection,
  store_name: String,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { get_one(_, query, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Retrieves all records within the range
/// from an object store.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.getAll`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/getAll)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "get")
pub fn get(
  store: ObjectStore,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves all records within the range
/// from an object store inside a new transaction.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`get`](#get).
/// 
pub fn quick_get(
  db: Connection,
  store_name: String,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { get(_, query, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Retrieves some records within the range
/// from an object store.
/// 
/// Limits the retrieved records to the amount specified on the third argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.getAll`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/getAll)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "getWithLimit")
pub fn get_with_limit(
  store: ObjectStore,
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves some records within the range
/// from an object store inside a new transaction.
/// 
/// Limits the retrieved records to the amount specified on the fourth argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`get_with_limit`](#get_with_limit).
/// 
pub fn quick_get_with_limit(
  db: Connection,
  store_name: String,
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { get_with_limit(_, query, limit, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Retrieves the first key within the range
/// from an object store.
/// 
/// The last argument is executed with the record key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.getKey`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/getKey)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "getOneKey")
pub fn get_one_key(
  store: ObjectStore,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves the first key within the range
/// from an object store inside a new transaction.
/// 
/// The last argument is executed with the record key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`get_one_key`](#get_one_key).
/// 
pub fn quick_get_one_key(
  db: Connection,
  store_name: String,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { get_one_key(_, query, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Retrieves all keys within the range
/// from an object store.
/// 
/// The last argument is executed with the record keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.getAllKeys`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/getAllKeys)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "getKeys")
pub fn get_keys(
  store: ObjectStore,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves all keys within the range
/// from an object store inside a new transaction.
/// 
/// The last argument is executed with the record keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`get_keys`](#get_keys).
/// 
pub fn quick_get_keys(
  db: Connection,
  store_name: String,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { get_keys(_, query, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Retrieves some keys within the range
/// from an object store.
/// 
/// Limits the retrieved keys to the amount specified on the third argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the record keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.getAllKeys`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/getAllKeys)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "getKeysWithLimit")
pub fn get_keys_with_limit(
  store: ObjectStore,
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves some keys within the range
/// from an object store inside a new transaction.
/// 
/// Limits the retrieved keys to the amount specified on the fourth argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the record keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`get_keys_with_limit`](#get_keys_with_limit).
/// 
pub fn quick_get_keys_with_limit(
  db: Connection,
  store_name: String,
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { get_keys_with_limit(_, query, limit, next) }
  |> quick_operation(db, store_name, ReadOnly, _, next)
}

/// Updates a record in an object store
/// or inserts a new record if it does not already exist.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.put`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/put)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "put")
pub fn put(
  store: ObjectStore,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Updates a record in an object store
/// or inserts a new record if it does not already exist 
/// inside a new transaction.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`put`](#put).
/// 
pub fn quick_put(
  db: Connection,
  store_name: String,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { put(_, value, next) }
  |> quick_operation(db, store_name, ReadWrite, _, next)
}

/// Updates a record using a specified key in an object store
/// or inserts a new record if it does not already exist.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBObjectStore.put`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/put)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "putTo")
pub fn put_to(
  store: ObjectStore,
  key: Key,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Updates a record using a specified key in an object store
/// or inserts a new record if it does not already exist 
/// inside a new transaction.
/// 
/// The last argument is executed with the key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_store_transaction`](#start_store_transaction) with [`put_to`](#put_to).
/// 
pub fn quick_put_to(
  db: Connection,
  store_name: String,
  key: Key,
  value: Json,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { put_to(_, key, value, next) }
  |> quick_operation(db, store_name, ReadWrite, _, next)
}

// ---- Index Functions -------------------------------------------------------

/// Retrieves a list of the names of the indexes 
/// currently referencing the object store.
/// 
@external(javascript, "./idb_ffi.ts", "getIndexNames")
pub fn get_index_names(store: ObjectStore) -> List(String)

/// Retrieves an index to be used for operations.
/// 
@external(javascript, "./idb_ffi.ts", "getIndex")
pub fn get_index(store: ObjectStore, name: String) -> Result(Index, IdbError)

/// Creates an index that referenced the specified 
/// object store with the specified name.
/// 
/// Can only be called using `ObjectStore` inside a `versionchange` transaction, 
/// will return an `Error` otherwise.
/// Use [`connect`](#connect) with [`on_upgrade`](#on_upgrade) 
/// to initialize a `versionchange` transaction.
/// 
/// Similar to the [`IDBObjectStore.createIndex`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/createIndex)
/// on the IndexedDB API.
/// 
pub fn create_index(
  store: ObjectStore,
  name: String,
  key: IndexKey,
) -> Result(Index, IdbError) {
  do_create_index(
    store,
    name,
    case key {
      index.Key(key)
      | index.UniqueKey(key)
      | index.MultiEntryKey(key)
      | index.MultiEntryUniqueKey(key) -> json.string(key)
      index.CompoundKey([]) | index.UniqueCompoundKey([]) -> json.string("")
      index.CompoundKey(keys) | index.UniqueCompoundKey(keys) ->
        case keys |> list.filter(fn(key) { !string.is_empty(key) }) {
          [] -> json.string("")
          keys -> json.array(keys, json.string)
        }
    },
    case key {
      index.Key(_) | index.CompoundKey(_) -> json.null()
      index.UniqueKey(_) | index.UniqueCompoundKey(_) ->
        json.object([
          #("unique", json.bool(True)),
        ])
      index.MultiEntryKey(_) ->
        json.object([
          #("multiEntry", json.bool(True)),
        ])
      index.MultiEntryUniqueKey(_) ->
        json.object([
          #("unique", json.bool(True)),
          #("multiEntry", json.bool(True)),
        ])
    },
  )
}

@external(javascript, "./idb_ffi.ts", "createIndex")
fn do_create_index(
  store: ObjectStore,
  name: String,
  key: Json,
  options: Json,
) -> Result(Index, IdbError)

/// Deletes an [index](https://developer.mozilla.org/docs/Web/API/IndexedDB_API/Basic_Terminology#index)
/// that referenced the specified object store with the specified name.
///
/// Can only be called using `ObjectStore` inside a `versionchange` transaction, 
/// will return an `Error` otherwise.
/// Use [`connect`](#connect) with [`on_upgrade`](#on_upgrade) 
/// to initialize a `versionchange` transaction.
/// 
/// Similar to the [`IDBObjectStore.deleteIndex`](https://developer.mozilla.org/docs/Web/API/IDBObjectStore/deleteIndex)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "deleteIndex")
pub fn delete_index(store: ObjectStore, name: String) -> Result(Nil, IdbError)

// ---- Index Operation Functions ---------------------------------------------

fn quick_index_operation(
  db: Connection,
  store_index_name: #(String, String),
  operation: fn(Index) -> Nil,
  next: fn(Result(a, IdbError)) -> b,
) -> Nil {
  {
    use store <- result.map(
      start_index_transaction(db, store_index_name, fn(_) { Nil }),
    )
    operation(store)
  }
  |> result.map_error(fn(e) {
    next(Error(e))
    Nil
  })
  |> result_unwrap()
}

/// Retrieves the total number of records within the range
/// in an index.
/// 
/// The last argument is executed with the result or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.count`](https://developer.mozilla.org/docs/Web/API/IDBIndex/count)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexCount")
pub fn index_count(
  index: Index,
  query: KeyRange,
  next: fn(Result(Int, IdbError)) -> a,
) -> Nil

/// Retrieves the total number of records within the range
/// in an index inside a new transaction.
/// 
/// The last argument is executed with the result or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_count`](#index_count).
/// 
pub fn quick_index_count(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  next: fn(Result(Int, IdbError)) -> a,
) -> Nil {
  { index_count(_, query, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

/// Retrieves the first record within the range
/// from an index.
/// 
/// The last argument is executed with the record value or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.get`](https://developer.mozilla.org/docs/Web/API/IDBIndex/get)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexGetOne")
pub fn index_get_one(
  index: Index,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves the first record within the range
/// from an index inside a new transaction.
/// 
/// The last argument is executed with the record value or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_get_one`](#index_get_one).
/// 
pub fn quick_index_get_one(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { index_get_one(_, query, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

/// Retrieves all records within the range
/// from an index.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.getAll`](https://developer.mozilla.org/docs/Web/API/IDBIndex/getAll)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexGet")
pub fn index_get(
  index: Index,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves all records within the range
/// from an index inside a new transaction.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_get`](#index_get).
/// 
pub fn quick_index_get(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { index_get(_, query, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

/// Retrieves some records within the range
/// from an index.
/// 
/// Limits the retrieved records to the amount specified on the third argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.getAll`](https://developer.mozilla.org/docs/Web/API/IDBIndex/getAll)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexGetWithLimit")
pub fn index_get_with_limit(
  index: Index,
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves some records within the range
/// from an index inside a new transaction.
/// 
/// Limits the retrieved records to the amount specified on the fourth argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the record values or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_get_with_limit`](#index_get_with_limit).
/// 
pub fn quick_index_get_with_limit(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { index_get_with_limit(_, query, limit, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

/// Retrieves the first key within the range
/// from an index.
/// 
/// The last argument is executed with the index key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.getKey`](https://developer.mozilla.org/docs/Web/API/IDBIndex/getKey)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexGetOneKey")
pub fn index_get_one_key(
  index: Index,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves the first key within the range
/// from an index inside a new transaction.
/// 
/// The last argument is executed with the index key or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_get_one_key`](#index_get_one_key).
/// 
pub fn quick_index_get_one_key(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { index_get_one_key(_, query, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

/// Retrieves all keys within the range
/// from an index.
/// 
/// The last argument is executed with the index keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.getAllKeys`](https://developer.mozilla.org/docs/Web/API/IDBIndex/getAllKeys)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexGetKeys")
pub fn index_get_keys(
  index: Index,
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves all keys within the range
/// from an index inside a new transaction.
/// 
/// The last argument is executed with the index keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_get_keys`](#index_get_keys).
/// 
pub fn quick_index_get_keys(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { index_get_keys(_, query, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

/// Retrieves some keys within the range
/// from an index.
/// 
/// Limits the retrieved keys to the amount specified on the third argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the index keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// Similar to the [`IDBIndex.getAllKeys`](https://developer.mozilla.org/docs/Web/API/IDBIndex/getAllKeys)
/// on the IndexedDB API.
/// 
@external(javascript, "./idb_ffi.ts", "indexGetKeysWithLimit")
pub fn index_get_keys_with_limit(
  index: Index,
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil

/// Retrieves some keys within the range
/// from an index inside a new transaction.
/// 
/// Limits the retrieved keys to the amount specified on the fourth argument.
/// If the limit is a negative `Int`, then it will be treated as no limit.
/// 
/// The last argument is executed with the index keys or an error 
/// when the operation is completed or errored.
/// The returned value is discarded.
/// 
/// This is an utility function that combines
/// [`start_index_transaction`](#start_index_transaction) with [`index_get_keys_with_limit`](#index_get_keys_with_limit).
/// 
pub fn quick_index_get_keys_with_limit(
  db: Connection,
  store_index_name: #(String, String),
  query: KeyRange,
  limit: Int,
  next: fn(Result(Dynamic, IdbError)) -> a,
) -> Nil {
  { index_get_keys_with_limit(_, query, limit, next) }
  |> quick_index_operation(db, store_index_name, _, next)
}

// ---- Util Functions --------------------------------------------------------

/// Same as the deprecated `result.unwrap`.
/// 
fn result_unwrap(result: Result(a, a)) -> a {
  case result {
    Ok(a) | Error(a) -> a
  }
}
