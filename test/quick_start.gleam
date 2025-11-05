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

pub type MyError {
  WrapIdbError(idb.IdbError)
  WrapDecodeError(List(decode.DecodeError))
}

pub type Cat {
  Cat(name: String)
}

fn cat_decoder() -> decode.Decoder(Cat) {
  todo
}
