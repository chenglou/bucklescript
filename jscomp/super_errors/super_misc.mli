(** Range coordinates all 1-indexed, like for editors. Otherwise this code
  would have way too many off-by-one errors *)
val print_file: is_warning:bool -> range:(int * int) * (int * int) -> lines:string array -> Format.formatter -> unit -> unit

(* This is taken from https://github.com/ocaml/ocaml/blob/4.03/utils/misc.mli#L260 *)
(* We're overriding the minimum necessary in order to inject our own coloring
  handling, e.g. color tags from Ext_color *)
module Color : sig
  val setup : Clflags.color_setting -> unit
  val set_color_tag_handling : Format.formatter -> unit
end
