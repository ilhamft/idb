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
