# idb

[![Package Version](https://img.shields.io/hexpm/v/idb)](https://hex.pm/packages/idb)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/idb/)
[![mit](https://img.shields.io/github/license/ilhamft/idb?color=brightgreen)](https://github.com/ilhamft/idb/blob/main/LICENSE)
[![gleam js](https://img.shields.io/badge/%20gleam%20%E2%9C%A8-JS-yellow)](https://gleam.run/news/v0.16-gleam-compiles-to-javascript/)

Gleam bindings for the [IndexedDB](https://developer.mozilla.org/docs/Web/API/IndexedDB_API) API.

## Installation

Add to your Gleam project:

```sh
gleam add idb
```

## Usage

### Getting data

```gleam
import gleam/dynamic/decode
import gleam/result
import idb
import idb/range

pub fn main() -> Nil {
  use db <- idb.try_connect("MyDatabase", 1, [])
  use tx <- result.try(
    idb.start_transaction(db, ["cats"], idb.ReadOnly, fn(_) { Nil }),
  )
  use store <- result.map(idb.get_store(tx, "cats"))
  use maybe_data <- idb.get_one(store, range.only(idb.key_int(1)))
  use data <- result.try(maybe_data |> result.map_error(WrapIdbError))
  let cat =
    data
    |> decode.run(cat_decoder())
    |> result.map_error(WrapDecodeError)
  case cat {
    Error(_) -> echo "errored"
    Ok(cat) -> echo "hello " <> cat.name
  }
  todo as "do something with the cat"
}
```

### Handling database upgrade

```gleam
import gleam/result
import idb
import idb/event
import idb/index
import idb/store

pub fn main() -> Nil {
  use db <- idb.try_connect("MyDatabase", 2, [
    event.OnUpgrade(handle_upgrade),
  ])
  todo as "do something with the db"
}

fn handle_upgrade(tx: idb.Transaction, old_version: Int, new_version: Int) {
  case old_version, new_version {
    1, 2 -> {
      use _ <- result.try(
        tx
        |> idb.delete_store("cats"),
      )
      use cat_store <- result.try(
        tx
        |> idb.create_store("cats", store.OutOfLineKey),
      )
      use _ <- result.try(
        cat_store
        |> idb.create_index("name_index", index.UniqueKey("name")),
      )
      use _ <- result.map(
        cat_store
        |> idb.create_index("age_index", index.Key("age")),
      )
      Nil
    }

    _, _ -> Ok(Nil)
  }
}
```

Documentations can be found at <https://hexdocs.pm/idb>.
