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


type bs_dependency = 
  {
    package_name : string ; 
    package_install_path : string ; 
  }
type bs_dependencies =
  bs_dependency list 
type t = 
  {
    package_name : string ; 
    ocamllex : string ; 
    external_includes : string list ; 
    bsc_flags : string list ;
    ppx_flags : string list ;
    bs_dependencies : bs_dependencies;
    
    built_in_dependency : bs_dependency option; 
    (*TODO: maybe we should always resolve bs-platform 
      so that we can calculate correct relative path in 
      [.merlin]
    *)
    refmt : string option;
    refmt_flags : string list;
    js_post_build_cmd : string option;
    package_specs : Bsb_config.package_specs ; 
    globbed_dirs : string list;
    bs_file_groups : Bsb_build_ui.file_group list ;
    files_to_install : String_hash_set.t ;
    generate_merlin : bool ; 
    reason_react_jsx : bool ; (* whether apply PPX transform or not*)
    reason_auto_format : bool ; (* whether or not to format the file before building it *)
  }