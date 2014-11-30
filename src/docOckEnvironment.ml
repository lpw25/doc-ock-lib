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

open DocOckPaths.Identifier

module StringTbl = Map.Make(String)

type 'a t =
  { modules : 'a module_ Ident.tbl;
    module_types : 'a module_type Ident.tbl;
    types : 'a type_ Ident.tbl;
    constructors : 'a constructor Ident.tbl;
    fields : 'a field Ident.tbl;
    type_extensions : 'a type_extension Ident.tbl;
    exceptions : 'a exception_ Ident.tbl;
    values : 'a value Ident.tbl;
    classes : 'a class_ Ident.tbl;
    class_signatures : 'a class_signature Ident.tbl;
    methods : 'a method_ StringTbl.t;
    instance_variables : 'a instance_variable StringTbl.t;
    labels : 'a label StringTbl.t;
    parents : 'a parent StringTbl.t;
    elements : 'a any StringTbl.t; }

let empty =
  { modules = Ident.empty;
    module_types = Ident.empty;
    types = Ident.empty;
    constructors = Ident.empty;
    fields = Ident.empty;
    type_extensions = Ident.empty;
    exceptions = Ident.empty;
    values = Ident.empty;
    classes = Ident.empty;
    class_signatures = Ident.empty;
    methods = StringTbl.empty;
    instance_variables = StringTbl.empty;
    labels = StringTbl.empty;
    parents = StringTbl.empty;
    elements = StringTbl.empty; }

let add_module parent id env =
  let name = Ident.name id in
  let identifier = Module(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             modules = Ident.add id identifier env.modules }

let add_argument parent arg id env =
  let name = Ident.name id in
  let identifier = Argument(parent, arg, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             modules = Ident.add id identifier env.modules }

let add_module_type parent id env =
  let name = Ident.name id in
  let identifier = ModuleType(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             module_types = Ident.add id identifier env.module_types }

let add_type parent id env =
  let name = Ident.name id in
  let identifier = Type(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             types = Ident.add id identifier env.types }

let add_value parent id env =
  let name = Ident.name id in
  let identifier = Value(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             values = Ident.add id identifier env.values }

let add_constructor parent id env =
  let name = Ident.name id in
  let identifier = Constructor(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             constructors = Ident.add id identifier env.constructors }

let add_field parent id env =
  let name = Ident.name id in
  let identifier = Field(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             fields = Ident.add id identifier env.fields }

let add_extension parent id env =
  let name = Ident.name id in
  let identifier = Extension(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             constructors = Ident.add id identifier env.constructors;
             type_extensions = Ident.add id identifier env.type_extensions }

let add_exception parent id env =
  let name = Ident.name id in
  let identifier = Exception(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             constructors = Ident.add id identifier env.constructors;
             type_extensions = Ident.add id identifier env.type_extensions;
             exceptions = Ident.add id identifier env.exceptions }

let add_class parent id ty_id obj_id cl_id env =
  let name = Ident.name id in
  let identifier = Class(parent, name) in
  let add_idents tbl =
    Ident.add id identifier
      (Ident.add ty_id identifier
         (Ident.add obj_id identifier
            (Ident.add cl_id identifier tbl)))
  in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             types = add_idents env.types;
             class_signatures = add_idents env.class_signatures;
             classes = add_idents env.classes }

let add_class_type parent id obj_id cl_id env =
  let name = Ident.name id in
  let cl_id = { cl_id with Ident.name = name } in
  let identifier = ClassType(parent, name) in
  let add_idents tbl =
    Ident.add id identifier
         (Ident.add obj_id identifier
            (Ident.add cl_id identifier tbl))
  in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             types = add_idents env.types;
             class_signatures = add_idents env.class_signatures }

let add_method parent name env =
  let identifier = Method(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             methods = StringTbl.add name identifier env.methods }

let add_instance_variable parent name env =
  let identifier = InstanceVariable(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             instance_variables = StringTbl.add name identifier env.instance_variables }

let add_label parent name env =
  let identifier = Label(parent, name) in
  { env with elements = StringTbl.add name identifier env.elements;
             labels = StringTbl.add name identifier env.labels }

let add_core_type id env =
  let name = Ident.name id in
  let identifier = CoreType name in
  { env with elements = StringTbl.add name identifier env.elements;
             parents = StringTbl.add name identifier env.parents;
             types = Ident.add id identifier env.types }

let add_core_exception id env =
  let name = Ident.name id in
  let identifier = CoreException name in
  { env with elements = StringTbl.add name identifier env.elements;
             constructors = Ident.add id identifier env.constructors;
             type_extensions = Ident.add id identifier env.type_extensions;
             exceptions = Ident.add id identifier env.exceptions }

let is_core_type = function
  | "int" -> true
  | "char" -> true
  | "string" -> true
  | "float" -> true
  | "bool" -> true
  | "unit" -> true
  | "exn" -> true
  | "array" -> true
  | "list" -> true
  | "option" -> true
  | "nativeint" -> true
  | "int32" -> true
  | "int64" -> true
  | "lazy_t" -> true
  | "bytes" -> true
  | _ -> false

let core_constructor_type = function
  | "false" -> Some "bool"
  | "true" -> Some "bool"
  | "()" -> Some "unit"
  | "[]" -> Some "list"
  | "::" -> Some "list"
  | "None" -> Some "option"
  | "Some" -> Some "option"
  | _ -> None

let is_core_exception = function
  | "Match_failure" -> true
  | "Out_of_memory" -> true
  | "Invalid_argument" -> true
  | "Failure" -> true
  | "Not_found" -> true
  | "Sys_error" -> true
  | "End_of_file" -> true
  | "Division_by_zero" -> true
  | "Stack_overflow" -> true
  | "Sys_blocked_io" -> true
  | "Assert_failure" -> true
  | "Undefined_recursive_module" -> true
  | _ -> false

let builtin_idents = List.map snd Predef.builtin_idents

let find_module env id =
  Ident.find_same id env.modules

let find_module_type env id =
  Ident.find_same id env.module_types

let find_type env id =
  try
    Ident.find_same id env.types
  with Not_found ->
    if List.mem id builtin_idents then
      let name = Ident.name id in
        if is_core_type name then CoreType name
        else raise Not_found
    else raise Not_found

let find_class env id =
  Ident.find_same id env.classes

let find_class_signature env id =
  Ident.find_same id env.class_signatures


let lookup_module env name =
  Ident.find_name name env.modules

let lookup_module_type env name =
  Ident.find_name name env.module_types

let lookup_type env name =
  try
    Ident.find_name name env.types
  with Not_found ->
    if is_core_type name then CoreType name
    else raise Not_found

let lookup_constructor env name =
  try
    Ident.find_name name env.constructors
  with Not_found ->
    if is_core_exception name then CoreException name
    else
      match core_constructor_type name with
      | Some typ -> Constructor(CoreType typ, name)
      | None -> raise Not_found

let lookup_field env name =
  Ident.find_name name env.fields

let lookup_type_extension env name =
  try
    Ident.find_name name env.type_extensions
  with Not_found ->
    if is_core_exception name then CoreException name
    else raise Not_found

let lookup_exception env name =
  try
    Ident.find_name name env.exceptions
  with Not_found ->
    if is_core_exception name then CoreException name
    else raise Not_found

let lookup_value env name =
  Ident.find_name name env.values

let lookup_class env name =
  Ident.find_name name env.classes

let lookup_class_signature env name =
  Ident.find_name name env.class_signatures

let lookup_method env name =
  StringTbl.find name env.methods

let lookup_instance_variable env name =
  StringTbl.find name env.instance_variables

let lookup_label env name =
  StringTbl.find name env.labels

let lookup_parent env name =
  try
    StringTbl.find name env.parents
  with Not_found ->
    if is_core_type name then CoreType name
    else raise Not_found

let lookup_element env name =
  try
    StringTbl.find name env.elements
  with Not_found ->
    if is_core_type name then CoreType name
    else if is_core_exception name then CoreException name
    else
      match core_constructor_type name with
      | Some typ -> Constructor(CoreType typ, name)
      | None -> raise Not_found


module Path = struct

  open DocOckPaths.Path.Resolved
  open DocOckPaths.Path

  let read_module_ident env id =
    if Ident.persistent id then Root (Ident.name id)
    else
      try
        Resolved (Identifier  (find_module env id))
      with Not_found -> assert false

  let read_module_type_ident env id =
    try
      Resolved (Identifier (find_module_type env id))
    with Not_found -> assert false

  let read_type_ident env id =
    try
      Resolved (Identifier (find_type env id))
    with Not_found -> assert false

  let read_class_ident env id : 'a class_ =
    try
      Resolved (Identifier (find_class env id))
    with Not_found -> assert false

  let read_class_signature_ident env id : 'a class_signature =
    try
      Resolved (Identifier (find_class_signature env id))
    with Not_found -> assert false

  let rec read_module env = function
    | Path.Pident id -> read_module_ident env id
    | Path.Pdot(p, s, _) -> Dot(read_module env p, s)
    | Path.Papply(p, arg) -> Apply(read_module env p, read_module env arg)

  let read_module_type env = function
    | Path.Pident id -> read_module_type_ident env id
    | Path.Pdot(p, s, _) -> Dot(read_module env p, s)
    | Path.Papply(p, arg)-> assert false

  let read_class env = function
    | Path.Pident id -> read_class_ident env id
    | Path.Pdot(p, s, _) -> Dot(read_module env p, s)
    | Path.Papply(p, arg)-> assert false

  let read_class_signature env = function
    | Path.Pident id -> read_class_signature_ident env id
    | Path.Pdot(p, s, _) -> Dot(read_module env p, s)
    | Path.Papply(p, arg)-> assert false

  let read_type env = function
    | Path.Pident id -> read_type_ident env id
    | Path.Pdot(p, s, _) -> Dot(read_module env p, s)
    | Path.Papply(p, arg)-> assert false

end

module Fragment = struct

  open DocOckPaths.Fragment.Resolved
  open DocOckPaths.Fragment

  let rec read_module = function
    | Longident.Lident s -> Dot(Resolved Root, s)
    | Longident.Ldot(p, s) -> Dot(module_signature (read_module p), s)
    | Longident.Lapply _ -> assert false

  let read_type = function
    | Longident.Lident s -> Dot(Resolved Root, s)
    | Longident.Ldot(p, s) -> Dot(module_signature (read_module p), s)
    | Longident.Lapply _ -> assert false

end

module Reference = struct

  open DocOckPaths.Reference.Resolved
  open DocOckPaths.Reference

  let read_module_ident env name =
    try
      Resolved (Identifier (lookup_module env name))
    with Not_found -> Root name

  let read_module_type_ident env name =
    try
      Resolved (Identifier (lookup_module_type env name))
    with Not_found -> Root name

  let read_type_ident env name =
    try
      Resolved (Identifier (lookup_type env name))
    with Not_found -> Root name


  let read_constructor_ident env name =
    try
      Resolved (Identifier (lookup_constructor env name))
    with Not_found -> Root name

  let read_field_ident env name =
    try
      Resolved (Identifier (lookup_field env name))
    with Not_found -> Root name

  let read_type_extension_ident env name =
    try
      Resolved (Identifier (lookup_type_extension env name))
    with Not_found -> Root name

  let read_exception_ident env name =
    try
      Resolved (Identifier (lookup_exception env name))
    with Not_found -> Root name

  let read_value_ident env name =
    try
      Resolved (Identifier (lookup_value env name))
    with Not_found -> Root name

  let read_class_ident env name =
    try
      Resolved (Identifier (lookup_class env name))
    with Not_found -> Root name

  let read_class_signature_ident env name =
    try
      Resolved (Identifier (lookup_class_signature env name))
    with Not_found -> Root name

  let read_method_ident env name =
    try
      Resolved (Identifier (lookup_method env name))
    with Not_found -> Root name

  let read_instance_variable_ident env name =
    try
      Resolved (Identifier (lookup_instance_variable env name))
    with Not_found -> Root name

  let read_label_ident env name =
    try
      Resolved (Identifier (lookup_label env name))
    with Not_found -> Root name

  let read_parent_ident env name =
    try
      Resolved (Identifier (lookup_parent env name))
    with Not_found -> Root name

  let read_element_ident env name =
    try
      Resolved (Identifier (lookup_element env name))
    with Not_found -> Root name

  let rec read_parent env = function
    | Longident.Lident s -> read_parent_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_module env s =
    match Longident.parse s with
    | Longident.Lident s -> read_module_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_module_type env s =
    match Longident.parse s with
    | Longident.Lident s -> read_module_type_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_type env s =
    match Longident.parse s with
    | Longident.Lident s -> read_type_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_constructor env s =
    match Longident.parse s with
    | Longident.Lident s -> read_constructor_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_field env s =
    match Longident.parse s with
    | Longident.Lident s -> read_field_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_type_extension env s =
    match Longident.parse s with
    | Longident.Lident s -> read_type_extension_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_exception env s =
    match Longident.parse s with
    | Longident.Lident s -> read_exception_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_value env s =
    match Longident.parse s with
    | Longident.Lident s -> read_value_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_class env s =
    match Longident.parse s with
    | Longident.Lident s -> read_class_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_class_signature env s =
    match Longident.parse s with
    | Longident.Lident s -> read_class_signature_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_method env s =
    match Longident.parse s with
    | Longident.Lident s -> read_method_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_instance_variable env s =
    match Longident.parse s with
    | Longident.Lident s -> read_instance_variable_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_label env s =
    match Longident.parse s with
    | Longident.Lident s -> read_label_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

  let read_element env s =
    match Longident.parse s with
    | Longident.Lident s -> read_element_ident env s
    | Longident.Ldot(lid, s) -> Dot(read_parent env lid, s)
    | Longident.Lapply(_, _) -> assert false

end
