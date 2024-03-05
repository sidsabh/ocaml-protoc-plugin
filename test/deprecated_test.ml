open Deprecated
[@@@ocaml.alert "-protobuf"] (* Disable deprecation warnings for protobuf*)

module T1 = Message1 (* Message deprecated *)
module T2 = Message2
type t1 = Message1.t (* Message deprecated *)
type t2 = Message2.t (* Field deprecated *)


let v1 = E1.E1 (* Enum deprecated *)
let v2 = E2.E2 (* Enum value deprecated *)
let v3 = E2.E3

let m2 : Message2.t = 4 (* Field deprecated *)

let m3 = Message3.{ a = 4; (* Field Deprecated *)
                    b = 5;
                    c = `X 5}

let _ = Service1.Method1.name (* Service deprecated *)
let _ = Service2.Method1.name (* Method deprecated *)
let _ = Service2.Method2.name
