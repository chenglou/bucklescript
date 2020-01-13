(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)



let () =  Bsb_log.setup () 
let (//) = Ext_path.combine
let force_regenerate = ref false
let exec = ref false
let node_lit = "node"
let current_theme = ref "basic"
let set_theme s = current_theme := s 
let generate_theme_with_path = ref None
let regen = "-regen"
let separator = "--"
let watch_mode = ref false
let make_world = ref false 
let do_install = ref false
let set_make_world () = make_world := true
let bs_version_string = Bs_version.version

let print_version_string () = 
  print_string bs_version_string;
  print_newline (); 
  exit 0 

let bsb_main_flags : (string * Arg.spec * string) list=
  [
    "-v", Arg.Unit print_version_string, 
    " Print version and exit";
    "-version", Arg.Unit print_version_string, 
    " Print version and exit";
    "-verbose", Arg.Unit Bsb_log.verbose,
    " Set the output(from bsb) to be verbose";
    "-w", Arg.Set watch_mode,
    " Watch mode" ;     
    "-clean-world", Arg.Unit (fun _ -> 
        Bsb_clean.clean_bs_deps  Bsb_global_paths.cwd),
    " Clean all bs dependencies";
    "-clean", Arg.Unit (fun _ -> 
        Bsb_clean.clean_self  Bsb_global_paths.cwd),
    " Clean only current project";
    "-make-world", Arg.Unit set_make_world,
    " Build all dependencies and itself ";
    "-install", Arg.Set do_install,
    " Install public interface files into lib/ocaml";
    "-init", Arg.String (fun path -> generate_theme_with_path := Some path),
    " Init sample project to get started. Note (`bsb -init sample` will create a sample project while `bsb -init .` will reuse current directory)";
    "-theme", Arg.String set_theme,
    " The theme for project initialization, default is basic(https://github.com/bucklescript/bucklescript/tree/master/jscomp/bsb/templates)";
    
    regen, Arg.Set force_regenerate,
    " (internal) Always regenerate build.ninja no matter bsconfig.json is changed or not (for debugging purpose)";
    "-themes", Arg.Unit Bsb_theme_init.list_themes,
    " List all available themes";
    "-where",
    Arg.Unit (fun _ -> 
        print_endline (Filename.dirname Sys.executable_name)),
    " Show where bsb.exe is located"
  ]


(*Note that [keepdepfile] only makes sense when combined with [deps] for optimization*)

(**  Invariant: it has to be the last command of [bsb] *)
let exec_command_then_exit  command =
  Bsb_log.info "@{<info>CMD:@} %s@." command;
  exit (Sys.command command ) 

(* Execute the underlying ninja build call, then exit (as opposed to keep watching) *)
let ninja_command_exit   ninja_args  =
  let ninja_args_len = Array.length ninja_args in
  let lib_artifacts_dir = Lazy.force Bsb_global_backend.lib_artifacts_dir in
  if Ext_sys.is_windows_or_cygwin then
    let path_ninja = Filename.quote Bsb_global_paths.vendor_ninja in 
    exec_command_then_exit 
      (if ninja_args_len = 0 then      
         Ext_string.inter3
           path_ninja "-C" lib_artifacts_dir
       else   
         let args = 
           Array.append 
             [| path_ninja ; "-C"; lib_artifacts_dir|]
             ninja_args in 
         Ext_string.concat_array Ext_string.single_space args)
  else
    let ninja_common_args = [|"ninja.exe"; "-C"; lib_artifacts_dir |] in 
    let args = 
      if ninja_args_len = 0 then ninja_common_args else 
        Array.append ninja_common_args ninja_args in 
    Bsb_log.info_args args ;      
    Unix.execvp Bsb_global_paths.vendor_ninja args      



(**
   Cache files generated:
   - .bsdircache in project root dir
   - .bsdeps in builddir

   What will happen, some flags are really not good
   ninja -C _build
*)
let usage = "Usage : bsb.exe <bsb-options> -- <ninja_options>\n\
             For ninja options, try ninja -h \n\
             ninja will be loaded either by just running `bsb.exe' or `bsb.exe .. -- ..`\n\
             It is always recommended to run ninja via bsb.exe \n\
             Bsb options are:"

let handle_anonymous_arg arg =
  raise (Arg.Bad ("Unknown arg \"" ^ arg ^ "\""))


let program_exit () =
  exit 0

let install_target config_opt =
  let config =
    match config_opt with
    | None ->
      let config = 
        Bsb_config_parse.interpret_json
          ~toplevel_package_specs:None
          ~per_proj_dir:Bsb_global_paths.cwd in
      let _ = Ext_list.iter config.file_groups.files (fun group -> 
          let check_file = match group.public with
            | Export_all -> fun _ -> true
            | Export_none -> fun _ -> false
            | Export_set set ->  
              fun module_name ->
                Set_string.mem set module_name in
          Map_string.iter group.sources 
            (fun  module_name module_info -> 
               if check_file module_name then 
                 begin Hash_set_string.add config.files_to_install module_info.name_sans_extension end
            )) in 
      config
    | Some config -> config in
  Bsb_world.install_targets Bsb_global_paths.cwd config

(* see discussion #929, if we catch the exception, we don't have stacktrace... *)
let () =
  try begin 
    match Sys.argv with 
    | [| _ |] ->  (* specialize this path [bsb.exe] which is used in watcher *)
      Bsb_ninja_regen.regenerate_ninja 
        ~toplevel_package_specs:None 
        ~forced:false 
        ~per_proj_dir:Bsb_global_paths.cwd  |> ignore;
      ninja_command_exit  [||] 

    | argv -> 
      begin
        match Ext_array.find_and_split argv Ext_string.equal separator with
        | `No_split
          ->
          begin
            Arg.parse bsb_main_flags handle_anonymous_arg usage;
            (* first, check whether we're in boilerplate generation mode, aka -init foo -theme bar *)
            match !generate_theme_with_path with
            | Some path -> Bsb_theme_init.init_sample_project ~cwd:Bsb_global_paths.cwd ~theme:!current_theme path
            | None -> 
              (* [-make-world] should never be combined with [-package-specs] *)
              let make_world = !make_world in 
              let force_regenerate = !force_regenerate in
              let do_install = !do_install in 
              if not make_world && not force_regenerate && not do_install then
                (* [regenerate_ninja] is not triggered in this case
                   There are several cases we wish ninja will not be triggered.
                   [bsb -clean-world]
                   [bsb -regen ]
                *)
                (if !watch_mode then 
                    program_exit ()) (* bsb -verbose hit here *)
              else
                (let config_opt = 
                   Bsb_ninja_regen.regenerate_ninja 
                     ~toplevel_package_specs:None 
                     ~forced:force_regenerate ~per_proj_dir:Bsb_global_paths.cwd   in
                 if make_world then begin
                   Bsb_world.make_world_deps Bsb_global_paths.cwd config_opt [||]
                 end;
                 if !watch_mode then begin
                   program_exit ()
                   (* ninja is not triggered in this case
                      There are several cases we wish ninja will not be triggered.
                      [bsb -clean-world]
                      [bsb -regen ]
                   *)
                 end else if make_world then begin
                   ninja_command_exit [||] 
                 end else if do_install then begin
                   install_target config_opt
                 end)
          end
        | `Split (bsb_args,ninja_args)
          -> (* -make-world all dependencies fall into this category *)
          begin
            Arg.parse_argv bsb_args bsb_main_flags handle_anonymous_arg usage ;
            let config_opt = 
              Bsb_ninja_regen.regenerate_ninja 
                ~toplevel_package_specs:None 
                ~per_proj_dir:Bsb_global_paths.cwd 
                ~forced:!force_regenerate in
            (* [-make-world] should never be combined with [-package-specs] *)
            if !make_world then
              Bsb_world.make_world_deps Bsb_global_paths.cwd config_opt ninja_args;
            if !do_install then
              install_target config_opt;
            if !watch_mode then program_exit ()
            else ninja_command_exit  ninja_args 
          end
      end
  end
  with 
  | Bsb_exception.Error e ->
    Bsb_exception.print Format.err_formatter e ;
    Format.pp_print_newline Format.err_formatter ();
    exit 2
  | Ext_json_parse.Error (start,_,e) -> 
    Format.fprintf Format.err_formatter
      "File %S, line %d\n\
       @{<error>Error:@} %a@."
      start.pos_fname start.pos_lnum
      Ext_json_parse.report_error e ;
    exit 2
  | Arg.Bad s 
  | Sys_error s -> 
    Format.fprintf Format.err_formatter
      "@{<error>Error:@} %s@."
      s ;
    exit 2
  | e -> Ext_pervasives.reraise e 
