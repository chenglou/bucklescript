(** Range coordinates all 1-indexed, like for editors. Otherwise this code
  would have way too many off-by-one errors *)
val print_file: is_warning:bool -> range:(int * int) * (int * int) -> lines:string array -> Format.formatter -> unit -> unit

(* taken from https://github.com/BuckleScript/ocaml/blob/d4144647d1bf9bc7dc3aadc24c25a7efa3a67915/utils/misc.ml?utf8=✓#L361 *)
(* We're overriding the minimum necessary in order to inject our own coloring
  handling, e.g. color tags from Ext_color *)
module Color : sig
  val setup : Clflags.color_setting -> unit
  val set_color_tag_handling : Format.formatter -> unit
end
