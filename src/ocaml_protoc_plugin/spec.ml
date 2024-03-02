module type T = sig
  type 'a message
  type 'a enum
  type 'a oneof
  type 'a oneof_elem
  type 'a map
end

module type Enum = sig
  type t
  val to_int: t -> int
  val from_int: int -> t Result.t
  val from_int_exn: int -> t
  val to_string: t -> string
  val from_string_exn: string -> t
end

module type Message = sig
  type t
  val from_proto: Reader.t -> t Result.t
  val from_proto_exn: Reader.t -> t
  val to_proto: t -> Writer.t
  val to_proto': Writer.t -> t -> Writer.t
  val merge: t -> t -> t
  val to_json: ?enum_names:bool -> ?json_names:bool -> ?omit_default_values:bool -> t -> Yojson.Basic.t
  val from_json_exn: Yojson.Basic.t -> t
  val from_json: Yojson.Basic.t -> t Result.t
end

module Make(T : T) = struct
  type packed = Packed | Not_packed
  type extension_ranges = (int * int) list
  type extensions = (int * Field.t) list
  type 'a merge = 'a -> 'a -> 'a

  type field = (int * string * string)

  type _ spec =
    | Double : float spec
    | Float : float spec

    | Int32 : Int32.t spec
    | UInt32 : Int32.t spec
    | SInt32 : Int32.t spec
    | Fixed32 : Int32.t spec
    | SFixed32 : Int32.t spec

    | Int32_int : int spec
    | UInt32_int : int spec
    | SInt32_int : int spec
    | Fixed32_int : int spec
    | SFixed32_int : int spec

    | UInt64 : Int64.t spec
    | Int64 : Int64.t spec
    | SInt64 : Int64.t spec
    | Fixed64 : Int64.t spec
    | SFixed64 : Int64.t spec

    | UInt64_int : int spec
    | Int64_int : int spec
    | SInt64_int : int spec
    | Fixed64_int : int spec
    | SFixed64_int : int spec

    | Bool : bool spec
    | String : string spec
    | Bytes : bytes spec
    | Enum :  (module Enum with type t = 'a) T.enum -> 'a spec
    | Message : (module Message with type t = 'a) T.message -> 'a spec

  (* Existential types *)
  type espec = Espec: _ spec -> espec [@@unboxed]

  type _ oneof =
    | Oneof_elem : field * 'b spec * (('b -> 'a) * ('a -> 'b)) T.oneof_elem -> 'a oneof

  type _ compound =
    (* A field, where the default value is know (and set). This cannot be used for message types *)
    | Basic : field * 'a spec * 'a -> 'a compound

    (* Proto2/proto3 optional fields. *)
    | Basic_opt : field * 'a spec -> 'a option compound

    (* Proto2 required fields (and oneof fields) *)
    | Basic_req : field * 'a spec -> 'a compound

    (* Repeated fields *)
    | Repeated : field * 'a spec * packed -> 'a list compound

    (* Map types *)
    | Map : field * (module Message with type t = ('a * 'b)) T.map -> ('a * 'b) list compound

    (* Oneofs. A list of fields + function to index the field *)
    | Oneof : (('a oneof list) * ('a -> int)) T.oneof -> ([> `not_set ] as 'a) compound

  type (_, _) compound_list =
    (* End of list *)
    | Nil : ('a, 'a) compound_list

    (* Nil_ext denotes that the message contains extensions *)
    | Nil_ext: extension_ranges -> (extensions -> 'a, 'a) compound_list

    (* List element *)
    | Cons : ('a compound) * ('b, 'c) compound_list -> ('a -> 'b, 'c) compound_list

  let double = Double
  let float = Float
  let int32 = Int32
  let int64 = Int64
  let uint32 = UInt32
  let uint64 = UInt64
  let sint32 = SInt32
  let sint64 = SInt64
  let fixed32 = Fixed32
  let fixed64 = Fixed64
  let sfixed32 = SFixed32
  let sfixed64 = SFixed64

  let int32_int = Int32_int
  let int64_int = Int64_int
  let uint32_int = UInt32_int
  let uint64_int = UInt64_int
  let sint32_int = SInt32_int
  let sint64_int = SInt64_int
  let fixed32_int = Fixed32_int
  let fixed64_int = Fixed64_int
  let sfixed32_int = SFixed32_int
  let sfixed64_int = SFixed64_int

  let bool = Bool
  let string = String
  let bytes = Bytes
  let enum f = Enum f
  let message f = Message f

  let some v = Some v
  let none = None
  let default_bytes v = (Some (Bytes.of_string v))

  let repeated (i, s, p) = Repeated (i, s, p)
  let map (i, s) = Map (i, s)
  let basic (i, s, d) = Basic (i, s, d)
  let basic_req (i, s) = Basic_req (i, s)
  let basic_opt (i, s) = Basic_opt (i, s)
  let oneof s = Oneof s
  let oneof_elem (a, b, c) = Oneof_elem (a, b, c)

  let packed = Packed
  let not_packed = Not_packed

  let ( ^:: ) a b = Cons (a, b)
  let nil = Nil
  let nil_ext extension_ranges = Nil_ext extension_ranges

  let show: type a. a spec -> string = function
    | Double -> "Double"
    | Float -> "Float"

    | Int32 -> "Int32"
    | UInt32 -> "UInt32"
    | SInt32 -> "SInt32"
    | Fixed32 -> "Fixed32"
    | SFixed32 -> "SFixed32"

    | Int32_int -> "Int32_int"
    | UInt32_int -> "UInt32_int"
    | SInt32_int -> "SInt32_int"
    | Fixed32_int -> "Fixed32_int"
    | SFixed32_int -> "SFixed32_int"

    | UInt64 -> "UInt64"
    | Int64 -> "Int64"
    | SInt64 -> "SInt64"
    | Fixed64 -> "Fixed64"
    | SFixed64 -> "SFixed64"

    | UInt64_int -> "UInt64_int"
    | Int64_int -> "Int64_int"
    | SInt64_int -> "SInt64_int"
    | Fixed64_int -> "Fixed64_int"
    | SFixed64_int -> "SFixed64_int"

    | Bool -> "Bool"
    | String -> "String"
    | Bytes -> "Bytes"
    | Enum _ -> "Enum"
    | Message _ -> "Message"
end

include Make(struct
    type 'a message = 'a
    type 'a enum = 'a
    type 'a oneof = 'a
    type 'a oneof_elem = 'a
    type 'a map = 'a
  end)
