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

(** Paths of documentation *)

(** {3 Path kinds} *)

type signature_kind = [ `Module | `ModuleType ]
type class_signature_kind = [ `Class | `ClassType ]
type container_kind = [ signature_kind | class_signature_kind ]
type type_kind = [ class_signature_kind | `Type ]
type parent_kind = [ container_kind | `Type ]
type type_extension_kind = [ `Extension | `Exception ]
type constructor_kind = [ type_extension_kind | `Constructor ]

type any_kind = [
  | parent_kind | constructor_kind
  | `Field | `Value | `Method | `InstanceVariable | `Label
  ]

(** {3 Identifiers} **)

(** Identifiers for definitions *)
module Identifier : sig

  type kind = any_kind

  type ('a, 'b) t =
    | Root : 'a -> ('a, [< kind > `Module]) t
    | Module : 'a signature * string -> ('a, [< kind > `Module]) t
    | Argument : 'a signature * int * string -> ('a, [< kind > `Module]) t
    | ModuleType : 'a signature * string -> ('a, [< kind > `ModuleType]) t
    | Type : 'a signature * string -> ('a, [< kind > `Type]) t
    | CoreType : string -> ('a, [< kind > `Type]) t
    | Constructor : 'a datatype * string -> ('a, [< kind > `Constructor]) t
    | Field : 'a datatype * string -> ('a, [< kind > `Field]) t
    | Extension : 'a signature * string -> ('a, [< kind > `Extension]) t
    | Exception : 'a signature * string -> ('a, [< kind > `Exception]) t
    | CoreException : string -> ('a, [< kind > `Exception]) t
    | Value : 'a signature * string -> ('a, [< kind > `Value]) t
    | Class : 'a signature * string -> ('a, [< kind > `Class]) t
    | ClassType : 'a signature * string -> ('a, [< kind > `ClassType]) t
    | Method : 'a class_signature * string -> ('a, [< kind > `Method]) t
    | InstanceVariable : 'a class_signature * string ->
                           ('a, [< kind > `InstanceVariable]) t
    | Label : 'a container * string -> ('a, [< kind > `Label]) t

  and 'a parent = ('a, parent_kind) t

  and 'a container = ('a, container_kind) t

  and 'a signature = ('a, signature_kind) t

  and 'a module_ = ('a, [`Module]) t

  and 'a module_type = ('a, [`ModuleType]) t

  and 'a datatype =  ('a, [`Type]) t

  and 'a variant_constructor = ('a, [`Constructor]) t

  and 'a field = ('a, [`Field]) t

  and 'a extension = ('a, [`Extension]) t

  and 'a exception_ = ('a, [`Exception]) t

  and 'a type_extension = ('a, type_extension_kind) t

  and 'a constructor = ('a, constructor_kind) t

  and 'a value = ('a, [`Value]) t

  and 'a class_ = ('a, [`Class]) t

  and 'a class_type = ('a, [`ClassType]) t

  and 'a class_signature = ('a, class_signature_kind) t

  and 'a type_ = ('a, type_kind) t

  and 'a method_ = ('a, [`Method]) t

  and 'a instance_variable = ('a, [`InstanceVariable]) t

  and 'a label = ('a, [`Label]) t

  and 'a any = ('a, kind) t

  val module_signature : 'a module_ -> 'a signature

  val module_type_signature : 'a module_type -> 'a signature

  val class_signature : 'a class_ -> 'a class_signature

  val class_type_signature : 'a class_type -> 'a class_signature

  val container_of_signature : 'a signature -> 'a container

  val container_of_class_signature : 'a class_signature -> 'a container

  val parent_of_signature : 'a signature -> 'a parent

  val parent_of_datatype : 'a datatype -> 'a parent

  val parent_of_class_signature : 'a class_signature -> 'a parent

  val parent_of_container : 'a container -> 'a parent

  val any : ('a, 'b) t -> 'a any

  val name : ('a, 'b) t -> string option

end

(** {3 Paths} *)

(** OCaml paths *)
module rec Path : sig

  module Resolved : sig

    type kind = parent_kind

    type ('a, 'b) t =
      | Identifier : ('a, 'b) Identifier.t -> ('a, [< kind] as 'b) t
      | Module : 'a module_ * string -> ('a, [< kind > `Module]) t
      | Apply : 'a module_ * 'a Path.module_ -> ('a, [< kind > `Module]) t
      | ModuleType : 'a module_ * string -> ('a, [< kind > `ModuleType]) t
      | Type : 'a module_ * string -> ('a, [< kind > `Type]) t
      | Class : 'a module_ * string -> ('a, [< kind > `Class]) t
      | ClassType : 'a module_ * string -> ('a, [< kind > `ClassType]) t

    and 'a module_ = ('a, [`Module]) t

    and 'a module_type = ('a, [`ModuleType]) t

    and 'a type_ = ('a, type_kind) t

    and 'a class_ = ('a, [`Class]) t

    and 'a class_type = ('a, [`ClassType]) t

    and 'a class_signature = ('a, class_signature_kind) t

    and 'a any = ('a, kind) t

    val ident_module : 'a Identifier.module_ -> 'a module_

    val ident_module_type : 'a Identifier.module_type -> 'a module_type

    val ident_type : 'a Identifier.datatype -> 'a type_

    val ident_class : 'a Identifier.class_ -> 'a class_

    val ident_class_type
      : 'a Identifier.class_type -> 'a class_signature

    val class_signature_of_class : 'a class_ -> 'a class_signature

    val type_of_class : 'a class_ -> 'a type_

    val type_of_class_signature : 'a class_signature -> 'a type_

    val any : ('a, 'b) t -> 'a any

    val identifier: ('a, 'b) t -> ('a, 'b) Identifier.t

  end

  type kind = Resolved.kind

  type ('a, 'b) t =
    | Resolved : ('a, 'b) Resolved.t -> ('a, 'b) t
    | Root : string -> ('a, [< kind > `Module]) t
    | Dot : 'a module_ * string -> ('a, [< kind]) t
    | Apply : 'a module_ * 'a module_ -> ('a, [< kind > `Module]) t

  and 'a module_ = ('a, [`Module]) t

  and 'a module_type = ('a, [`ModuleType]) t

  and 'a type_ = ('a, type_kind) t

  and 'a class_ = ('a, [`Class]) t

  and 'a class_type = ('a, [`ClassType]) t

  and 'a class_signature = ('a, class_signature_kind) t

  and 'a any = ('a, kind) t

  val ident_module : 'a Identifier.module_ -> 'a module_

  val ident_module_type : 'a Identifier.module_type -> 'a module_type

  val ident_type : 'a Identifier.datatype -> 'a type_

  val ident_class : 'a Identifier.class_ -> 'a class_

  val ident_class_type
    : 'a Identifier.class_type -> 'a class_signature

  val class_signature_of_class : 'a class_ -> 'a class_signature

  val type_of_class : 'a class_ -> 'a type_

  val type_of_class_signature : 'a class_signature -> 'a type_

  val any : ('a, 'b) t -> 'a any

  val module_ : 'a module_ -> string -> 'a module_

  val apply : 'a module_ -> 'a module_ -> 'a module_

  val module_type : 'a module_ -> string -> 'a module_type

  val type_ : 'a module_ -> string -> 'a type_

  val class_ : 'a module_ -> string -> 'a class_

  val class_type_ : 'a module_ -> string -> 'a class_type

end

(** {3 Fragments} *)

(** OCaml path fragments for specifying module substitutions *)
module Fragment : sig

  module Resolved : sig

    type kind = [ type_kind | `Module ]

    type sort = [ `Root | `Branch ]

    type ('a, 'b) raw =
      | Root : ('a, [< sort > `Root]) raw
      | Module : signature * string -> ([< kind > `Module], [< sort > `Branch]) raw
      | Type : signature * string -> ([< kind > `Type], [< sort > `Branch]) raw
      | Class : signature * string -> ([< kind > `Class], [< sort > `Branch]) raw
      | ClassType : signature * string -> ([< kind > `ClassType], [< sort > `Branch]) raw

    and signature = ([`Module], [`Root | `Branch]) raw

    and 'a t = ('a, [`Branch]) raw

    and module_ = [`Module] t

    and type_ = type_kind t

    and any = kind t

    val module_signature : module_ -> signature

    val any : 'a t -> any

    val path: 'a Path.module_ -> 'b t -> ('a, 'b) Path.t

    val identifier: 'a Identifier.signature -> 'b t ->
                    ('a, 'b) Identifier.t

    val split : 'a t -> string * 'a t option

  end

  type kind = Resolved.kind

  type sort = [ `Root | `Branch ]

  type ('a, 'b) raw =
    | Resolved : ('a, 'b) Resolved.raw -> ('a, 'b) raw
    | Dot : signature * string -> ([< kind], [< sort > `Branch]) raw

  and signature = ([`Module], [`Root | `Branch]) raw

  and 'a t = ('a, [`Branch]) raw

  and module_ = [`Module] t

  and type_ = type_kind t

  and any = kind t

  val module_signature : module_ -> signature

  val any : 'a t -> any

  val path: 'a Path.module_ -> 'b t -> ('a, 'b) Path.t

  val split: 'a t -> string * 'a t option

end


(** {3 References} *)

(** References to definitions *)
module Reference : sig

  module Resolved : sig

    type kind = any_kind

    type ('a, 'b) t =
      | Identifier : ('a, 'b) Identifier.t -> ('a, 'b) t
      | Module : 'a signature * string -> ('a, [< kind > `Module]) t
      | ModuleType : 'a signature * string -> ('a, [< kind > `ModuleType]) t
      | Type : 'a signature * string -> ('a, [< kind > `Type]) t
      | Constructor : 'a datatype * string -> ('a, [< kind > `Constructor]) t
      | Field : 'a datatype * string -> ('a, [< kind > `Field]) t
      | Extension : 'a signature * string -> ('a, [< kind > `Extension]) t
      | Exception : 'a signature * string -> ('a, [< kind > `Exception]) t
      | Value : 'a signature * string -> ('a, [< kind > `Value]) t
      | Class : 'a signature * string -> ('a, [< kind > `Class]) t
      | ClassType : 'a signature * string -> ('a, [< kind > `ClassType]) t
      | Method : 'a class_signature * string -> ('a, [< kind > `Method]) t
      | InstanceVariable : 'a class_signature * string ->
                             ('a, [< kind > `InstanceVariable]) t
      | Label : 'a container * string -> ('a, [< kind > `Label]) t

    and 'a parent = ('a, parent_kind) t

    and 'a container = ('a, container_kind) t

    and 'a module_ = ('a, [`Module]) t

    and 'a module_type = ('a, [`ModuleType]) t

    and 'a signature = ('a, signature_kind) t

    and 'a type_ = ('a, type_kind) t

    and 'a datatype = ('a, [`Type]) t

    and 'a constructor = ('a, constructor_kind) t

    and 'a field = ('a, [`Field]) t

    and 'a type_extension = ('a, type_extension_kind) t

    and 'a exception_ = ('a, [`Exception]) t

    and 'a value = ('a, [`Value]) t

    and 'a class_ = ('a, [`Class]) t

    and 'a class_type = ('a, [`ClassType]) t

    and 'a class_signature = ('a, class_signature_kind) t

    and 'a method_ = ('a, [`Method]) t

    and 'a instance_variable = ('a, [`InstanceVariable]) t

    and 'a label = ('a, [`Label]) t

    and 'a any = ('a, kind) t

    val ident_module : 'a Identifier.module_ -> 'a module_

    val ident_module_type : 'a Identifier.module_type -> 'a module_type

    val ident_type : 'a Identifier.datatype -> 'a type_

    val ident_datatype : 'a Identifier.datatype -> 'a datatype

    val ident_constructor : 'a Identifier.variant_constructor -> 'a constructor

    val ident_field : 'a Identifier.field -> 'a field

    val ident_extension : 'a Identifier.extension -> 'a type_extension

    val ident_exception : 'a Identifier.exception_ -> 'a exception_

    val ident_value : 'a Identifier.value -> 'a value

    val ident_class : 'a Identifier.class_ -> 'a class_

    val ident_class_type : 'a Identifier.class_type -> 'a class_signature

    val ident_method : 'a Identifier.method_ -> 'a method_

    val ident_instance_variable : 'a Identifier.instance_variable ->
                                    'a instance_variable

    val ident_label : 'a Identifier.label -> 'a label

    val module_signature : 'a module_ -> 'a signature

    val module_type_signature : 'a module_type -> 'a signature

    val class_signature : 'a class_ -> 'a class_signature

    val class_type_signature : 'a class_type -> 'a class_signature

    val container_of_signature : 'a signature -> 'a container

    val container_of_class_signature : 'a class_signature -> 'a container

    val parent_of_signature : 'a signature -> 'a parent

    val parent_of_class_signature : 'a class_signature -> 'a parent

    val parent_of_datatype : 'a datatype -> 'a parent

    val parent_of_container : 'a container -> 'a parent

    val class_signature_of_class : 'a class_ -> 'a class_signature

    val type_of_datatype : 'a datatype -> 'a type_

    val type_of_class : 'a class_ -> 'a type_

    val type_of_class_type : 'a class_type -> 'a type_

    val type_of_class_signature : 'a class_signature -> 'a type_

    val type_extension_of_exception : 'a exception_ -> 'a type_extension

    val constructor_of_type_extension : 'a type_extension -> 'a constructor

    val constructor_of_exception : 'a exception_ -> 'a constructor

    val any : ('a, 'b) t -> 'a any

    val identifier: ('a, 'b) t -> ('a, 'b) Identifier.t

  end

  type kind = Resolved.kind

  type ('a, 'b) t =
    | Resolved : ('a, 'b) Resolved.t -> ('a, 'b) t
    | Root : string -> ('a, [< kind]) t
    | Dot : 'a parent * string -> ('a, [< kind]) t

  and 'a parent = ('a, parent_kind) t

  and 'a container = ('a, container_kind) t

  and 'a module_ = ('a, [`Module]) t

  and 'a module_type = ('a, [`ModuleType]) t

  and 'a signature = ('a, signature_kind) t

  and 'a type_ = ('a, type_kind) t

  and 'a datatype = ('a, [`Type]) t

  and 'a constructor = ('a, constructor_kind) t

  and 'a field = ('a, [`Field]) t

  and 'a type_extension = ('a, type_extension_kind) t

  and 'a exception_ = ('a, [`Exception]) t

  and 'a value = ('a, [`Value]) t

  and 'a class_ = ('a, [`Class]) t

  and 'a class_type = ('a, [`ClassType]) t

  and 'a class_signature = ('a, class_signature_kind) t

  and 'a method_ = ('a, [`Method]) t

  and 'a instance_variable = ('a, [`InstanceVariable]) t

  and 'a label = ('a, [`Label]) t

  and 'a any = ('a, kind) t


  val ident_module : 'a Identifier.module_ -> 'a module_

  val ident_module_type : 'a Identifier.module_type -> 'a module_type

  val ident_type : 'a Identifier.datatype -> 'a type_

  val ident_datatype : 'a Identifier.datatype -> 'a datatype

  val ident_constructor : 'a Identifier.variant_constructor -> 'a constructor

  val ident_field : 'a Identifier.field -> 'a field

  val ident_extension : 'a Identifier.extension -> 'a type_extension

  val ident_exception : 'a Identifier.exception_ -> 'a exception_

  val ident_value : 'a Identifier.value -> 'a value

  val ident_class : 'a Identifier.class_ -> 'a class_

  val ident_class_type : 'a Identifier.class_type -> 'a class_signature

  val ident_method : 'a Identifier.method_ -> 'a method_

  val ident_instance_variable : 'a Identifier.instance_variable ->
                                  'a instance_variable

  val ident_label : 'a Identifier.label -> 'a label

  val module_signature : 'a module_ -> 'a signature

  val module_type_signature : 'a module_type -> 'a signature

  val class_signature : 'a class_ -> 'a class_signature

  val class_type_signature : 'a class_type -> 'a class_signature

  val container_of_signature : 'a signature -> 'a container

  val container_of_class_signature : 'a class_signature -> 'a container

  val parent_of_signature : 'a signature -> 'a parent

  val parent_of_class_signature : 'a class_signature -> 'a parent

  val parent_of_datatype : 'a datatype -> 'a parent

  val parent_of_container : 'a container -> 'a parent

  val class_signature_of_class : 'a class_ -> 'a class_signature

  val type_of_datatype : 'a datatype -> 'a type_

  val type_of_class : 'a class_ -> 'a type_

  val type_of_class_type : 'a class_type -> 'a type_

  val type_extension_of_exception : 'a exception_ -> 'a type_extension

  val constructor_of_type_extension : 'a type_extension -> 'a constructor

  val constructor_of_exception : 'a exception_ -> 'a constructor

  val any : ('a, 'b) t -> 'a any

end
