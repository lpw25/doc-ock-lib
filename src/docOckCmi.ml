(*
 * Copyright (c) 2014 Leo White <lpw25@cl.cam.ac.uk>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Asttypes
open Parsetree
open Types

module OCamlPath = Path

open DocOckPaths
open DocOckTypes
open DocOckAttrs

module Env = DocOckEnvironment

let opt_map f = function
  | None -> None
  | Some x -> Some (f x)

let opt_iter f = function
  | None -> ()
  | Some x -> f x

let read_label lbl =
  let open TypeExpr in
  let len = String.length lbl in
  if len = 0 then None
  else if lbl.[0] = '?' then
    Some (Optional (String.sub lbl 1 (len - 1)))
  else Some (Label lbl)

(* Handle type variable names *)

let used_names = ref []
let name_counter = ref 0
let reserved_names = ref []

let reset_names () = used_names := []; name_counter := 0; reserved_names := []

let reserve_name = function
  | Some name ->
      if not (List.mem name !reserved_names) then
        reserved_names := name :: !reserved_names
  | None -> ()

let rec next_name () =
  let name =
    if !name_counter < 26
    then String.make 1 (Char.chr(97 + !name_counter))
    else String.make 1 (Char.chr(97 + !name_counter mod 26)) ^
           string_of_int(!name_counter / 26)
  in
    incr name_counter;
    if List.mem name !reserved_names then next_name ()
    else name

let rec fresh_name base =
  let current_name = ref base in
  let i = ref 0 in
  while List.exists (fun (_, name') -> !current_name = name') !used_names do
    current_name := base ^ (string_of_int !i);
    i := !i + 1;
  done;
  !current_name

let name_of_type (ty : Types.type_expr) =
  try
    List.assq ty !used_names
  with Not_found ->
    let base =
      match ty.desc with
      | Tvar (Some name) | Tunivar (Some name) -> name
      | _ -> next_name ()
    in
    let name = fresh_name base in
    if name <> "_" then used_names := (ty, name) :: !used_names;
    name

let remove_names tyl =
  used_names := List.filter (fun (ty,_) -> not (List.memq ty tyl)) !used_names

(* Handle recursive types and shared row variables *)

let aliased = ref []
let used_aliases = ref []

let reset_aliased () = aliased := []; used_aliases := []

let is_aliased px = List.memq px !aliased

let aliasable (ty : Types.type_expr) =
  match ty.desc with
  | Tvar _ | Tunivar _ | Tpoly _ -> false
  | _ -> true

let add_alias ty =
  let px = Btype.proxy ty in
  if not (List.memq px !aliased) then begin
    aliased := px :: !aliased;
    match px.desc with
    | Tvar name | Tunivar name -> reserve_name name
    | _ -> ()
  end

let used_alias (px : Types.type_expr) = List.memq px !used_aliases

let use_alias (px : Types.type_expr) = used_aliases := px :: !used_aliases

let visited_rows = ref []

let reset_visited_rows () = visited_rows := []

let is_row_visited px = List.memq px !visited_rows

let visit_row px =
  visited_rows := px :: !visited_rows

let visit_object ty px =
  if Ctype.opened_object ty then
    visited_rows := px :: !visited_rows

let namable_row row =
  row.row_name <> None &&
  List.for_all
    (fun (_, f) ->
       match Btype.row_field_repr f with
       | Reither(c, l, _, _) ->
           row.row_closed && if c then l = [] else List.length l = 1
       | _ -> true)
    row.row_fields

let mark_type ty =
  let rec loop visited ty =
    let ty = Btype.repr ty in
    let px = Btype.proxy ty in
    if List.memq px visited && aliasable ty then add_alias px else
      let visited = px :: visited in
      match ty.desc with
      | Tvar name -> reserve_name name
      | Tarrow(_, ty1, ty2, _) ->
          loop visited ty1;
          loop visited ty2
      | Ttuple tyl -> List.iter (loop visited) tyl
      | Tconstr(p, tyl, _) ->
          List.iter (loop visited) tyl
      | Tvariant row ->
          if is_row_visited px then add_alias px else
           begin
            let row = Btype.row_repr row in
            if not (Btype.static_row row) then visit_row px;
            match row.row_name with
            | Some(p, tyl) when namable_row row ->
                List.iter (loop visited) tyl
            | _ ->
                Btype.iter_row (loop visited) row
           end
      | Tobject (fi, nm) ->
          if is_row_visited px then add_alias px else
           begin
            visit_object ty px;
            match !nm with
            | None ->
                let fields, _ = Ctype.flatten_fields fi in
                List.iter
                  (fun (_, kind, ty) ->
                    if Btype.field_kind_repr kind = Fpresent then
                      loop visited ty)
                  fields
            | Some (_, l) ->
                List.iter (loop visited) (List.tl l)
          end
      | Tfield(_, kind, ty1, ty2) when Btype.field_kind_repr kind = Fpresent ->
          loop visited ty1;
          loop visited ty2
      | Tfield(_, _, _, ty2) ->
          loop visited ty2
      | Tnil -> ()
      | Tpoly (ty, tyl) ->
          List.iter (fun t -> add_alias t) tyl;
          loop visited ty
      | Tunivar name -> reserve_name name
      | Tpackage(_, _, tyl) ->
          List.iter (loop visited) tyl
      | Tsubst ty -> loop visited ty
      | Tlink _ -> assert false
  in
  loop [] ty

let mark_type_parameter param =
  add_alias param;
  mark_type param;
  if aliasable param then use_alias (Btype.proxy param)

let prepare_type_parameters params manifest =
  let params =
    List.fold_left
      (fun params param ->
        let param = Btype.repr param in
        if List.memq param params then Btype.newgenty (Tsubst param) :: params
        else param :: params)
      [] params
  in
  let params = List.rev params in
  begin match manifest with
    | Some ty ->
        let vars = Ctype.free_variables ty in
          List.iter
            (function {desc = Tvar (Some "_")} as ty ->
              if List.memq ty vars then ty.desc <- Tvar None
                    | _ -> ())
            params
    | None -> ()
  end;
  params

let mark_type_kind = function
  | Type_abstract -> ()
  | Type_variant cds ->
      List.iter
        (fun cd ->
           List.iter mark_type cd.cd_args;
           opt_iter mark_type cd.cd_res)
        cds
  | Type_record(lds, _) ->
      List.iter (fun ld -> mark_type ld.ld_type) lds
  | Type_open -> ()

let mark_extension_constructor ext =
  List.iter mark_type ext.ext_args;
  opt_iter mark_type ext.ext_ret_type

let rec mark_class_type params = function
  | Cty_constr (p, tyl, cty) ->
      let sty = Ctype.self_type cty in
      if is_row_visited (Btype.proxy sty)
      || List.exists aliasable params
      || List.exists (Ctype.deep_occur sty) tyl
      then mark_class_type params cty
      else List.iter mark_type tyl
  | Cty_signature sign ->
      let sty = Btype.repr sign.csig_self in
      let px = Btype.proxy sty in
      if is_row_visited px then add_alias sty
      else visit_row px;
      let (fields, _) =
        Ctype.flatten_fields (Ctype.object_fields sign.csig_self)
      in
      List.iter (fun (_, _, ty) -> mark_type ty) fields;
      Vars.iter (fun _ (_, _, ty) -> mark_type ty) sign.csig_vars;
      if is_aliased sty && aliasable sty then use_alias px
  | Cty_arrow (_, ty, cty) ->
      mark_type ty;
      mark_class_type params cty

let rec read_type_expr env typ =
  let open TypeExpr in
  let typ = Btype.repr typ in
  let px = Btype.proxy typ in
  if used_alias px then Var (name_of_type typ)
  else begin
    let alias =
      if not (is_aliased px && aliasable typ) then None
      else begin
        use_alias px;
        Some (name_of_type typ)
      end
    in
    let typ =
      match typ.desc with
      | Tvar _ ->
          let name = name_of_type typ in
            if name = "_" then Any
            else Var name
      | Tarrow(lbl, arg, res, _) ->
          let arg =
            if Btype.is_optional lbl then
              match (Btype.repr arg).desc with
              | Tconstr(path, [arg], _)
                  when OCamlPath.same path Predef.path_option ->
                    read_type_expr env arg
              | _ -> assert false
            else read_type_expr env arg
          in
          let lbl = read_label lbl in
          let res = read_type_expr env res in
            Arrow(lbl, arg, res)
      | Ttuple typs ->
          let typs = List.map (read_type_expr env) typs in
            Tuple typs
      | Tconstr(p, params, _) ->
          let p = Env.Path.read_type env p in
          let params = List.map (read_type_expr env) params in
            Constr(p, params)
      | Tvariant row -> read_row env px row
      | Tobject (fi, nm) -> read_object env fi !nm
      | Tnil | Tfield _ -> read_object env typ None
      | Tpoly (typ, []) -> read_type_expr env typ
      | Tpoly (typ, tyl) ->
          let tyl = List.map Btype.repr tyl in
          let vars = List.map name_of_type tyl in
          let typ = read_type_expr env typ in
            remove_names tyl;
            Poly(vars, typ)
      | Tunivar _ -> Var (name_of_type typ)
      | Tpackage(p, frags, tyl) ->
          let open TypeExpr.Package in
          let path = Env.Path.read_module_type env p in
          let substitutions =
            List.map2
              (fun frag typ ->
                 let frag = Env.Fragment.read_type frag in
                 let typ = read_type_expr env typ in
                   (frag, typ))
              frags tyl
          in
            Package {path; substitutions}
      | Tsubst typ -> read_type_expr env typ
      | Tlink _ -> assert false
    in
      match alias with
      | None -> typ
      | Some name -> Alias(typ, name)
  end

and read_row env px row =
  let open TypeExpr in
  let open TypeExpr.Variant in
  let row = Btype.row_repr row in
  let fields =
    if row.row_closed then
      List.filter (fun (_, f) -> Btype.row_field_repr f <> Rabsent)
        row.row_fields
    else row.row_fields in
  let sorted_fields = List.sort (fun (p,_) (q,_) -> compare p q) fields in
  let present =
    List.filter
      (fun (_, f) ->
         match Btype.row_field_repr f with
         | Rpresent _ -> true
         | _ -> false)
      sorted_fields in
  let all_present = List.length present = List.length sorted_fields in
  match row.row_name with
  | Some(p, params) when namable_row row ->
      let p = Env.Path.read_type env p in
      let params = List.map (read_type_expr env) params in
      if row.row_closed && all_present then
        Constr (p, params)
      else
        let kind =
          if all_present then Open else Closed (List.map fst present)
        in
        Variant {kind; elements = [Type (Constr (p, params))]}
  | _ ->
      let elements =
        List.map
          (fun (l, f) ->
            match Btype.row_field_repr f with
              | Rpresent None ->
                  Constructor(l, true, [])
              | Rpresent (Some typ) ->
                  Constructor(l, false, [read_type_expr env typ])
              | Reither(c, typs, _, _) ->
                  let typs =
                    List.map (read_type_expr env) typs
                  in
                    Constructor(l, c, typs)
              | Rabsent -> assert false)
          sorted_fields
      in
      let kind =
        if all_present then
          if row.row_closed then Fixed
          else Open
        else Closed (List.map fst present)
      in
      Variant {kind; elements}

and read_object env fi nm =
  let open TypeExpr in
  let open TypeExpr.Object in
  match nm with
  | None ->
      let (fields, rest) = Ctype.flatten_fields fi in
      let present_fields =
        List.fold_right
          (fun (n, k, t) l ->
             match Btype.field_kind_repr k with
             | Fpresent -> (n, t) :: l
             | _ -> l)
          fields []
      in
      let sorted_fields =
        List.sort (fun (n, _) (n', _) -> compare n n') present_fields
      in
      let methods =
        List.map
          (fun (name, typ) -> {name; type_ = read_type_expr env typ})
          sorted_fields
      in
      let open_ =
        match rest.desc with
        | Tvar _ | Tunivar _ -> true
        | Tconstr _ -> true
        | Tnil -> false
        | _ -> assert false
      in
      Object {methods; open_}
  | Some (p, _ :: params) ->
      let p = Env.Path.read_class_signature env p in
      let params = List.map (read_type_expr env) params in
      Class (p, params)
  | _ -> assert false

let read_type_scheme env typ =
  reset_names ();
  reset_aliased ();
  reset_visited_rows ();
  mark_type typ;
  read_type_expr env typ

let add_value_description parent id vd env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container vd.val_attributes env in
  let env = Env.add_value parent id env in
    env

let read_value_description env parent id vd =
  let open Signature in
  let id = Identifier.Value(parent, Ident.name id) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container vd.val_attributes in
  let type_ = read_type_scheme env vd.val_type in
  match vd.val_kind with
  | Val_reg -> Value {Value.id; doc; type_}
  | Val_prim desc ->
      let primitives = Primitive.description_list desc in
        External {External.id; doc; type_; primitives}
  | _ -> assert false

let add_constructor_declaration container parent cd env =
  let env = add_attributes container cd.cd_attributes env in
  let env = Env.add_constructor parent cd.cd_id env in
    env

let read_constructor_declaration env container parent cd =
  let open TypeDecl.Constructor in
  let id = Identifier.Constructor(parent, Ident.name cd.cd_id) in
  let doc = read_attributes env container cd.cd_attributes in
  let args = List.map (read_type_expr env) cd.cd_args in
  let res = opt_map (read_type_expr env) cd.cd_res in
    {id; doc; args; res}

let add_label_declaration container parent ld env =
  let env = add_attributes container ld.ld_attributes env in
  let env = Env.add_field parent ld.ld_id env in
    env

let read_label_declaration env container parent ld =
  let open TypeDecl.Field in
  let id = Identifier.Field(parent, Ident.name ld.ld_id) in
  let doc = read_attributes env container ld.ld_attributes in
  let type_ = read_type_expr env ld.ld_type in
    {id; doc; type_}

let add_type_kind container parent kind env =
  match kind with
  | Type_abstract -> env
  | Type_variant cstrs ->
      List.fold_right
        (add_constructor_declaration container parent)
        cstrs env
  | Type_record(lbls, _) ->
      List.fold_right
        (add_label_declaration container parent)
        lbls env
  | Type_open -> env

let read_type_kind env container parent =
  let open TypeDecl.Representation in function
    | Type_abstract -> None
    | Type_variant cstrs ->
        let cstrs =
          List.map (read_constructor_declaration env container parent) cstrs
        in
          Some (Variant cstrs)
    | Type_record(lbls, _) ->
        let lbls =
          List.map (read_label_declaration env container parent) lbls
        in
          Some (Record lbls)
    | Type_open ->  Some Extensible

let read_type_parameter abstr var param =
  let open TypeDecl in
  let name = name_of_type param in
  let desc =
    if name = "_" then Any
    else Var name
  in
  let var =
    if not (abstr || aliasable param) then None
    else begin
      let co, cn = Variance.get_upper var in
        if not cn then Some Pos
        else if not co then Some Neg
        else None
    end
  in
    (desc, var)

let read_type_constraints env params =
  List.fold_right
    (fun typ1 acc ->
       let typ2 = Ctype.unalias typ1 in
       if Btype.proxy typ1 != Btype.proxy typ2 then
         let typ1 = read_type_expr env typ1 in
         let typ2 = read_type_expr env typ2 in
           (typ1, typ2) :: acc
       else acc)
    params []

let add_type_declaration parent id decl env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container decl.type_attributes env in
  let id' = Identifier.Type(parent, Ident.name id) in
  let env = add_type_kind container id' decl.type_kind env in
  let env = Env.add_type parent id env in
    env

let read_type_declaration env parent id decl =
  let open TypeDecl in
  let id = Identifier.Type(parent, Ident.name id) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container decl.type_attributes in
  let params = prepare_type_parameters decl.type_params decl.type_manifest in
    reset_names ();
    reset_aliased ();
    reset_visited_rows ();
    List.iter mark_type_parameter params;
    opt_iter mark_type decl.type_manifest;
    mark_type_kind decl.type_kind;
    let manifest = opt_map (read_type_expr env) decl.type_manifest in
    let constraints = read_type_constraints env params in
    let representation = read_type_kind env container id decl.type_kind in
    let abstr =
      match decl.type_kind with
        Type_abstract ->
          decl.type_manifest = None || decl.type_private = Private
      | Type_record _ ->
          decl.type_private = Private
      | Type_variant tll ->
          decl.type_private = Private ||
          List.exists (fun cd -> cd.cd_res <> None) tll
      | Type_open ->
          decl.type_manifest = None
    in
    let params =
      List.map2 (read_type_parameter abstr) decl.type_variance params
    in
    let private_ = (decl.type_private = Private) in
    let equation = Equation.{params; manifest; constraints; private_} in
      {id; doc; equation; representation}

let add_extension_constructor parent id ext env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container ext.ext_attributes env in
  let env = Env.add_extension parent id env in
    env

let read_extension_constructor env parent id ext =
  let open Extension.Constructor in
  let id = Identifier.Extension(parent, Ident.name id) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container ext.ext_attributes in
  let args = List.map (read_type_expr env) ext.ext_args in
  let res = opt_map (read_type_expr env) ext.ext_ret_type in
    {id; doc; args; res}

let read_type_extension env parent id ext rest =
  let open Extension in
  let type_path = Env.Path.read_type env ext.ext_type_path in
  let doc = empty in
  let type_params = prepare_type_parameters ext.ext_type_params None in
    reset_names ();
    reset_aliased ();
    reset_visited_rows ();
    List.iter mark_type_parameter type_params;
    mark_extension_constructor ext;
    List.iter (fun (_, ext) -> mark_extension_constructor ext) rest;
    let first = read_extension_constructor env parent id ext in
    let rest =
      List.map
        (fun (id, ext) -> read_extension_constructor env parent id ext)
        rest
    in
    let constructors = first :: rest in
    let type_params =
      List.map (read_type_parameter false Variance.null) type_params
    in
    let private_ = (ext.ext_private = Private) in
      { type_path; type_params;
        doc; private_;
        constructors; }

let add_exception parent id ext env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container ext.ext_attributes env in
  let env = Env.add_exception parent id env in
    env

let read_exception env parent id ext =
  let open Exception in
  let id = Identifier.Exception(parent, Ident.name id) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container ext.ext_attributes in
    reset_names ();
    reset_aliased ();
    reset_visited_rows ();
    mark_extension_constructor ext;
    let args = List.map (read_type_expr env) ext.ext_args in
    let res = opt_map (read_type_expr env) ext.ext_ret_type in
      {id; doc; args; res}

let add_method parent (name, _, _) env =
  Env.add_method parent name env

let read_method env parent concrete (name, kind, typ) =
  let open Method in
  let id = Identifier.Method(parent, name) in
  let doc = empty in
  let private_ = (Btype.field_kind_repr kind) <> Fpresent in
  let virtual_ = not (Concr.mem name concrete) in
  let type_ = read_type_expr env typ in
    ClassSignature.Method {id; doc; private_; virtual_; type_}

let add_instance_variable parent (name, _, _, _) env =
  Env.add_instance_variable parent name env

let read_instance_variable env parent (name, mutable_, virtual_, typ) =
  let open InstanceVariable in
  let id = Identifier.InstanceVariable(parent, name) in
  let doc = empty in
  let mutable_ = (mutable_ = Mutable) in
  let virtual_ = (virtual_ = Virtual) in
  let type_ = read_type_expr env typ in
    ClassSignature.InstanceVariable {id; doc; mutable_; virtual_; type_}

let rec read_class_signature env parent params =
  let open ClassType in function
  | Cty_constr(p, tyl, cty) ->
      if is_row_visited (Btype.proxy (Ctype.self_type cty))
      || List.exists aliasable params
      then read_class_signature env parent params cty
      else begin
        let p = Env.Path.read_class_signature env p in
        let params = List.map (read_type_expr env) params in
          Constr(p, params)
      end
  | Cty_signature csig ->
      let open ClassSignature in
      let instance_variables =
        Vars.fold
          (fun name (mutable_, virtual_, typ) acc ->
             (name, mutable_, virtual_, typ) :: acc)
          csig.csig_vars []
      in
      let methods, _ =
        Ctype.flatten_fields (Ctype.object_fields csig.csig_self)
      in
      let methods =
        List.filter (fun (name, _, _) -> name <> Btype.dummy_method) methods
      in
      let env =
        List.fold_right
          (add_instance_variable parent)
          instance_variables env
      in
      let env = List.fold_right (add_method parent) methods env in
      let sty = Btype.repr csig.csig_self in
      let self =
        if not (is_aliased sty) then None
        else Some (TypeExpr.Var (name_of_type (Btype.proxy sty)))
      in
      let constraints = read_type_constraints env params in
      let constraints =
        List.map
          (fun (typ1, typ2) -> Constraint(typ1, typ2))
          constraints
      in
      let instance_variables =
        List.map (read_instance_variable env parent) instance_variables
      in
      let methods =
        List.map (read_method env parent csig.csig_concr) methods
      in
      let items = constraints @ instance_variables @ methods in
        Signature {self; items}
  | Cty_arrow _ -> assert false

let rec read_virtual = function
  | Cty_constr(_, _, cty) | Cty_arrow(_, _, cty) -> read_virtual cty
  | Cty_signature csig ->
      let methods, _ =
        Ctype.flatten_fields (Ctype.object_fields csig.csig_self)
      in
      let virtual_method =
        List.exists
          (fun (name, _, _) ->
             not (name = Btype.dummy_method
                 || Concr.mem name csig.csig_concr))
          methods
      in
      let virtual_instance_variable =
        Vars.exists
          (fun _ (_, virtual_, _) -> virtual_ = Virtual)
          csig.csig_vars
      in
        virtual_method || virtual_instance_variable

let add_class_type_declaration parent id obj_id cl_id cltd env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container cltd.clty_attributes env in
  let env = Env.add_class_type parent id obj_id cl_id env in
    env

let read_class_type_declaration env parent id cltd =
  let open ClassType in
  let name = Ident.name id in
  let id = Identifier.ClassType(parent, name) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container cltd.clty_attributes in
    reset_names ();
    reset_aliased ();
    reset_visited_rows ();
    List.iter mark_type_parameter cltd.clty_params;
    mark_class_type cltd.clty_params cltd.clty_type;
    let params =
      List.map2
        (read_type_parameter false)
        cltd.clty_variance cltd.clty_params
    in
    let expr =
      read_class_signature env id cltd.clty_params cltd.clty_type
    in
    let virtual_ = read_virtual cltd.clty_type in
      { id; doc; virtual_; params; expr }

let rec read_class_type env parent params =
  let open Class in function
  | Cty_constr _ | Cty_signature _ as cty ->
      ClassType (read_class_signature env parent params cty)
  | Cty_arrow(lbl, arg, cty) ->
      let arg =
        if Btype.is_optional lbl then
          match (Btype.repr arg).desc with
          | Tconstr(path, [arg], _)
            when OCamlPath.same path Predef.path_option ->
              read_type_expr env arg
          | _ -> assert false
        else read_type_expr env arg
      in
      let lbl = read_label lbl in
      let cty = read_class_type env parent params cty in
        Arrow(lbl, arg, cty)

let add_class_declaration parent id ty_id obj_id cl_id cld env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container cld.cty_attributes env in
  let env = Env.add_class parent id ty_id obj_id cl_id env in
    env

let read_class_declaration env parent id cld =
  let open Class in
  let name = Ident.name id in
  let id = Identifier.Class(parent, name) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container cld.cty_attributes in
    reset_names ();
    reset_aliased ();
    reset_visited_rows ();
    List.iter mark_type_parameter cld.cty_params;
    mark_class_type cld.cty_params cld.cty_type;
    let params =
      List.map2
        (read_type_parameter false)
        cld.cty_variance cld.cty_params
    in
    let type_ =
      read_class_type env id cld.cty_params cld.cty_type
    in
    let virtual_ = cld.cty_new = None in
      { id; doc; virtual_; params; type_ }

let add_module_type_declaration parent id mtd env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container mtd.mtd_attributes env in
  let env = Env.add_module_type parent id env in
    env

let add_module_declaration parent id md env =
  let container = Identifier.container_of_signature parent in
  let env = add_attributes container md.md_attributes env in
  let env = Env.add_module parent id env in
    env

let rec add_signature_items parent items env =
  match items with
  | Sig_value(id, vd) :: rest ->
      let env = add_signature_items parent rest env in
        add_value_description parent id vd env
  | Sig_type(id, _, _) :: rest when Btype.is_row_name (Ident.name id) ->
      add_signature_items parent rest env
  | Sig_type(id, decl, _) :: rest ->
      let env = add_signature_items parent rest env in
        add_type_declaration parent id decl env
  | Sig_typext(id, tyext, (Text_first | Text_next)) :: rest ->
      let env = add_signature_items parent rest env in
        add_extension_constructor parent id tyext env
  | Sig_typext(id, ext, Text_exception) :: rest ->
      let env = add_signature_items parent rest env in
        add_exception parent id ext env
  | Sig_module(id, md, _) :: rest ->
      let env = add_signature_items parent rest env in
        add_module_declaration parent id md env
  | Sig_modtype(id, mtd) :: rest ->
      let env = add_signature_items parent rest env in
        add_module_type_declaration parent id mtd env
  | Sig_class(id, cl, _) :: Sig_class_type(ty_id, _, _)
      :: Sig_type(obj_id, _, _) :: Sig_type(cl_id, _, _) :: rest ->
      let env = add_signature_items parent rest env in
        add_class_declaration parent id ty_id obj_id cl_id cl env
  | Sig_class _ :: _ -> assert false
  | Sig_class_type(id, cltyp, _) :: Sig_type(obj_id, _, _)
    :: Sig_type(cl_id, _, _) :: rest ->
      let env = add_signature_items parent rest env in
        add_class_type_declaration parent id obj_id cl_id cltyp env
  | Sig_class_type _ :: _ -> assert false
  | [] -> env

let rec read_module_type env parent pos mty =
  let open ModuleType in
    match mty with
    | Mty_ident p -> Ident (Env.Path.read_module_type env p)
    | Mty_signature sg -> Signature (read_signature env parent sg)
    | Mty_functor(id, arg, res) ->
        let arg =
          match arg with
          | None -> None
          | Some arg ->
              let name = Ident.name id in
              let id = Identifier.Argument(parent, pos, name) in
              let arg = read_module_type env id 1 arg in
                Some (id, arg)
        in
        let env = Env.add_argument parent pos id env in
        let res = read_module_type env parent (pos + 1) res in
          Functor(arg, res)
    | Mty_alias _ -> assert false

and read_module_type_declaration env parent id mtd =
  let open ModuleType in
  let name = Ident.name id in
  let id = Identifier.ModuleType(parent, name) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container mtd.mtd_attributes in
  let expr = opt_map (read_module_type env id 1) mtd.mtd_type in
    {id; doc; expr}

and read_module_declaration env parent id md =
  let open Module in
  let name = Ident.name id in
  let id = Identifier.Module(parent, name) in
  let container = Identifier.container_of_signature parent in
  let doc = read_attributes env container md.md_attributes in
  let type_ =
    match md.md_type with
    | Mty_alias p -> Alias (Env.Path.read_module env p)
    | _ -> ModuleType (read_module_type env id 1 md.md_type)
  in
    {id; doc; type_}

and read_signature env parent items =
  let env = add_signature_items parent items env in
  let rec loop acc items =
    let open Signature in
    match items with
    | Sig_value(id, v) :: rest ->
        let vd = read_value_description env parent id v in
          loop (vd :: acc) rest
    | Sig_type(id, _, _) :: rest when Btype.is_row_name (Ident.name id) ->
        loop acc rest
    | Sig_type(id, decl, _) :: rest ->
        let decl = read_type_declaration env parent id decl in
          loop (Type decl :: acc) rest
    | Sig_typext (id, ext, Text_first) :: rest ->
        let rec inner_loop inner_acc = function
          | Sig_typext(id, ext, Text_next) :: rest ->
              inner_loop ((id, ext) :: inner_acc) rest
          | rest ->
              let ext =
                read_type_extension env parent id ext (List.rev inner_acc)
              in
                loop (TypExt ext :: acc) rest
        in
          inner_loop [] rest
    | Sig_typext (id, ext, Text_next) :: rest ->
        let ext = read_type_extension env parent id ext [] in
          loop (TypExt ext :: acc) rest
    | Sig_typext (id, ext, Text_exception) :: rest ->
        let exn = read_exception env parent id ext in
          loop (Exception exn :: acc) rest
    | Sig_module(id, md, _) :: rest ->
        let md = read_module_declaration env parent id md in
          loop (Module md :: acc) rest
    | Sig_modtype(id, mtd) :: rest ->
        let mtd = read_module_type_declaration env parent id mtd in
          loop (ModuleType mtd :: acc) rest
    | Sig_class(id, cl, _) :: Sig_class_type _
      :: Sig_type _ :: Sig_type _ :: rest ->
        let cl = read_class_declaration env parent id cl in
          loop (Class cl :: acc) rest
    | Sig_class _ :: _ -> assert false
    | Sig_class_type(id, cltyp, _) :: Sig_type _ :: Sig_type _ :: rest ->
        let cltyp = read_class_type_declaration env parent id cltyp in
          loop (ClassType cltyp :: acc) rest
    | Sig_class_type _ :: _ -> assert false
    | [] -> List.rev acc
  in
    loop [] items

let read_interface root intf =
  let open Module in
  let id = Identifier.Root root in
  let doc = empty in
  let items = read_signature Env.empty id intf in
    (id, doc, items)
