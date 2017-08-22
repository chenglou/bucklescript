open Format
open Types


(* taken from https://github.com/BuckleScript/ocaml/blob/d4144647d1bf9bc7dc3aadc24c25a7efa3a67915/typing/printtyp.mli *) 
(* this is the only thing we need exposed *)
val report_unification_error:
    formatter -> Env.t -> ?unif:bool -> (type_expr * type_expr) list ->
    (formatter -> unit) -> (formatter -> unit) ->
    unit
