// @ts-ignore
import { Ok, Error as GError, List } from './gleam.mjs';
// @ts-ignore
import { list_to_array } from '../gleam_stdlib/gleam_stdlib.mjs';
// @ts-ignore
import { Some, None } from '../gleam_stdlib/gleam/option.mjs';

declare class Ok<T> {
  0: T;
  constructor($0: T);
}
declare class GError<T> {
  0: T;
  constructor($0: T);
}
declare class Some<T> {
  0: T;
  constructor($0: T);
}
declare class None {}

export function key(key: IDBValidKey | List<IDBValidKey>): IDBValidKey {
  if (key instanceof List) return list_to_array(key);
  return key;
}

export function keyRangeAll(): undefined {
  return undefined;
}

export function keyRangeOnly(key: IDBValidKey): IDBKeyRange {
  return IDBKeyRange.only(key);
}

export function keyRangeLowerBound(key: IDBValidKey): IDBKeyRange {
  return IDBKeyRange.lowerBound(key);
}

export function keyRangeExclusiveLowerBound(key: IDBValidKey): IDBKeyRange {
  return IDBKeyRange.lowerBound(key, true);
}

export function keyRangeUpperBound(key: IDBValidKey): IDBKeyRange {
  return IDBKeyRange.upperBound(key);
}

export function keyRangeExclusiveUpperBound(key: IDBValidKey): IDBKeyRange {
  return IDBKeyRange.upperBound(key, true);
}

export function keyRangeBound(
  lower: IDBValidKey,
  upper: IDBValidKey,
  lowerOpen: boolean,
  upperOpen: boolean
): IDBKeyRange {
  return IDBKeyRange.bound(lower, upper, lowerOpen, upperOpen);
}

export function keyRangeIncludes(
  key: IDBValidKey,
  range: IDBKeyRange
): boolean {
  return range.includes(key);
}

export function getDatabases(
  next: (result: Ok<[string, number][]> | GError<any>) => void
): void {
  window.indexedDB
    .databases()
    .then((databases) =>
      next(
        new Ok(
          databases.reduce<[string, number][]>((acc, db) => {
            if (!db.name) return acc;
            return [...acc, [db.name, db.version ?? 1]];
          }, [])
        )
      )
    )
    .catch((error) => next(new GError(error)));
}

export function connect(
  name: string,
  version: number,
  onUpgradeNeeded:
    | Some<
        (tx: IDBTransaction, currentVersion: number, newVersion: number) => void
      >
    | None,
  onBlocked: Some<(currentVersion: number, newVersion: number) => void> | None,
  onVersionChange:
    | Some<(currentVersion: number, blockedVersion: number) => void>
    | None,
  onClose: Some<() => void> | None,
  next: (result: Ok<IDBDatabase> | GError<any>) => void
): void {
  const request = window.indexedDB.open(name, version);
  if (onBlocked instanceof Some)
    request.onblocked = (event) => onBlocked[0](event.oldVersion, version);
  if (onUpgradeNeeded instanceof Some)
    request.onupgradeneeded = (event) => {
      if (!request.transaction) {
        return next(new GError('request.transaction is missing'));
      }
      onUpgradeNeeded[0](request.transaction, event.oldVersion, version);
    };
  request.onerror = () => next(new GError(request.error));
  request.onsuccess = () => {
    const db = request.result;
    if (onVersionChange instanceof Some)
      db.onversionchange = (event) =>
        onVersionChange[0](version, event.newVersion ?? 1);
    if (onClose instanceof Some) db.onclose = onClose[0];
    next(new Ok(db));
  };
}

export function deleteDatabase(
  name: string,
  next: (result: Ok<undefined> | GError<any>) => void
): void {
  try {
    const request = window.indexedDB.deleteDatabase(name);
    request.onerror = () => next(new GError(request.error));
    request.onsuccess = () => next(new Ok(undefined));
  } catch (error) {
    next(new GError(error));
  }
}

export function startTransaction(
  db: IDBDatabase,
  storeNames: string[],
  mode: 'readonly' | 'readwrite',
  onClose: (result: Ok<undefined> | GError<any>) => void
): Ok<IDBTransaction> | GError<any> {
  try {
    const tx = db.transaction(storeNames, mode);
    tx.onabort = () => onClose(new GError(tx.error));
    tx.onerror = () => onClose(new GError(tx.error));
    tx.oncomplete = () => onClose(new Ok(undefined));
    return new Ok(tx);
  } catch (error) {
    return new GError(error);
  }
}

export function getStoreNames(db: IDBDatabase): string[] {
  return Array.from(db.objectStoreNames);
}

export function getTransactionStoreNames(tx: IDBTransaction): string[] {
  return Array.from(tx.objectStoreNames);
}

export function getStore(
  tx: IDBTransaction,
  name: string
): Ok<IDBObjectStore> | GError<any> {
  try {
    return new Ok(tx.objectStore(name));
  } catch (error) {
    return new GError(error);
  }
}

export function createStore(
  tx: IDBTransaction,
  name: string,
  options: IDBObjectStoreParameters | null
): Ok<IDBObjectStore> | GError<any> {
  try {
    const db = tx.db;
    return new Ok(db.createObjectStore(name, options ?? undefined));
  } catch (error) {
    return new GError(error);
  }
}

export function deleteStore(
  tx: IDBTransaction,
  name: string
): Ok<undefined> | GError<any> {
  try {
    const db = tx.db;
    db.deleteObjectStore(name);
    return new Ok(undefined);
  } catch (error) {
    return new GError(error);
  }
}

function handleRequest<T>(
  requestFn: () => IDBRequest<T>,
  next: (result: Ok<T> | GError<any>) => void
): void {
  try {
    const request = requestFn();
    request.onerror = () => next(new GError(request.error));
    request.onsuccess = () => next(new Ok(request.result));
  } catch (error) {
    next(new GError(error));
  }
}

export function add(
  store: IDBObjectStore,
  value: any,
  next: (result: Ok<IDBValidKey> | GError<any>) => void
): void {
  handleRequest(() => store.add(value), next);
}

export function addTo(
  store: IDBObjectStore,
  key: IDBValidKey,
  value: any,
  next: (result: Ok<IDBValidKey> | GError<any>) => void
): void {
  handleRequest(() => store.add(value, key), next);
}

export function count(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  next: (result: Ok<number> | GError<any>) => void
): void {
  handleRequest(() => store.count(query), next);
}

export function delete_(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  next: (result: Ok<any> | GError<any>) => void
): void {
  handleRequest(() => {
    if (query) return store.delete(query);
    return store.clear();
  }, next);
}

export function getOne(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  next: (result: Ok<any> | GError<any>) => void
): void {
  if (query) return handleRequest(() => store.get(query), next);
  handleRequest(
    () => store.getAll(),
    (x) => {
      if (x instanceof Ok) return next(new Ok(x[0][0]));
      return next(x);
    }
  );
}

export function get(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  next: (result: Ok<any> | GError<any>) => void
): void {
  handleRequest(() => store.getAll(query), next);
}

export function getWithLimit(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  limit: number,
  next: (result: Ok<any> | GError<any>) => void
): void {
  handleRequest(
    () => store.getAll(query, limit >= 0 ? limit : undefined),
    next
  );
}

export function getOneKey(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  next: (result: Ok<IDBValidKey | undefined> | GError<any>) => void
): void {
  if (query) handleRequest(() => store.getKey(query), next);
  handleRequest(
    () => store.getAllKeys(),
    (x) => {
      if (x instanceof Ok) return next(new Ok(x[0][0]));
      return next(x);
    }
  );
}

export function getKeys(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  next: (result: Ok<IDBValidKey[]> | GError<any>) => void
): void {
  handleRequest(() => store.getAllKeys(query), next);
}

export function getKeysWithLimit(
  store: IDBObjectStore,
  query: IDBKeyRange | undefined,
  limit: number,
  next: (result: Ok<IDBValidKey[]> | GError<any>) => void
): void {
  handleRequest(
    () => store.getAllKeys(query, limit >= 0 ? limit : undefined),
    next
  );
}

export function put(
  store: IDBObjectStore,
  value: any,
  next: (result: Ok<IDBValidKey> | GError<any>) => void
): void {
  handleRequest(() => store.put(value), next);
}

export function putTo(
  store: IDBObjectStore,
  key: IDBValidKey,
  value: any,
  next: (result: Ok<IDBValidKey> | GError<any>) => void
): void {
  handleRequest(() => store.put(value, key), next);
}

export function getIndexNames(store: IDBObjectStore): string[] {
  return Array.from(store.indexNames);
}

export function getIndex(
  store: IDBObjectStore,
  name: string
): Ok<IDBIndex> | GError<any> {
  try {
    return new Ok(store.index(name));
  } catch (error) {
    return new GError(error);
  }
}

export function createIndex(
  store: IDBObjectStore,
  name: string,
  key: string | string[],
  options: IDBIndexParameters | null
): Ok<IDBIndex> | GError<any> {
  try {
    return new Ok(store.createIndex(name, key, options ?? undefined));
  } catch (error) {
    return new GError(error);
  }
}

export function deleteIndex(
  store: IDBObjectStore,
  name: string
): Ok<undefined> | GError<any> {
  try {
    return new Ok(store.deleteIndex(name));
  } catch (error) {
    return new GError(error);
  }
}

export function indexCount(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  next: (result: Ok<number> | GError<any>) => void
): void {
  handleRequest(() => index.count(query), next);
}

export function indexGetOne(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  next: (result: Ok<any> | GError<any>) => void
): void {
  if (query) return handleRequest(() => index.get(query), next);
  handleRequest(
    () => index.getAll(),
    (x) => {
      if (x instanceof Ok) return next(new Ok(x[0][0]));
      return next(x);
    }
  );
}

export function indexGet(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  next: (result: Ok<any> | GError<any>) => void
): void {
  handleRequest(() => index.getAll(query), next);
}

export function indexGetWithLimit(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  limit: number,
  next: (result: Ok<any> | GError<any>) => void
): void {
  handleRequest(
    () => index.getAll(query, limit >= 0 ? limit : undefined),
    next
  );
}

export function indexGetOneKey(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  next: (result: Ok<IDBValidKey | undefined> | GError<any>) => void
): void {
  if (query) handleRequest(() => index.getKey(query), next);
  handleRequest(
    () => index.getAllKeys(),
    (x) => {
      if (x instanceof Ok) return next(new Ok(x[0][0]));
      return next(x);
    }
  );
}

export function indexGetKeys(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  next: (result: Ok<IDBValidKey[]> | GError<any>) => void
): void {
  handleRequest(() => index.getAllKeys(query), next);
}

export function indexGetKeysWithLimit(
  index: IDBIndex,
  query: IDBKeyRange | undefined,
  limit: number,
  next: (result: Ok<IDBValidKey[]> | GError<any>) => void
): void {
  handleRequest(
    () => index.getAllKeys(query, limit >= 0 ? limit : undefined),
    next
  );
}
