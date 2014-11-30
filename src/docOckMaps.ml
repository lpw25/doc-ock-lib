
open DocOckPaths
open DocOckTypes

let rec list_map f l =
  match l with
  | [] -> l
  | x :: r ->
      let x' = f x in
        if x != x' then x' :: List.map f r
        else
          let r' = list_map f r in
            if r != r' then x' :: r'
            else l

let rec option_map f o =
  match o with
  | None -> o
  | Some x ->
      let x' = f x in
        if x != x' then Some x'
        else o

class virtual ['a] documentation = object (self)

  method virtual identifier_label :
    'a Identifier.label -> 'a Identifier.label

  method virtual reference_module :
    'a Reference.module_ -> 'a Reference.module_

  method virtual reference_module_type :
    'a Reference.module_type -> 'a Reference.module_type

  method virtual reference_type :
    'a Reference.type_ -> 'a Reference.type_

  method virtual reference_constructor :
    'a Reference.constructor -> 'a Reference.constructor

  method virtual reference_field :
    'a Reference.field -> 'a Reference.field

  method virtual reference_extension :
    'a Reference.type_extension -> 'a Reference.type_extension

  method virtual reference_exception :
    'a Reference.exception_ -> 'a Reference.exception_

  method virtual reference_value :
    'a Reference.value -> 'a Reference.value

  method virtual reference_class :
    'a Reference.class_ -> 'a Reference.class_

  method virtual reference_class_signature :
    'a Reference.class_signature -> 'a Reference.class_signature

  method virtual reference_method :
    'a Reference.method_ -> 'a Reference.method_

  method virtual reference_instance_variable :
    'a Reference.instance_variable -> 'a Reference.instance_variable

  method virtual reference_label :
    'a Reference.label -> 'a Reference.label

  method virtual reference_any :
    'a Reference.any -> 'a Reference.any

  method documentation_style ds =
    let open Documentation in
      match ds with
      | Bold | Italic | Emphasize
      | Center | Left | Right
      | Superscript | Subscript -> ds
      | Custom custom ->
          let custom' = self#documentation_style_custom custom in
            if custom != custom' then Custom custom'
            else ds

  method documentation_style_custom custom = custom

  method documentation_reference drf =
    let open Documentation in
      match drf with
      | Module rf ->
          let rf' = self#reference_module rf in
            if rf != rf' then Module rf'
            else drf
      | ModuleType rf ->
          let rf' = self#reference_module_type rf in
            if rf != rf' then ModuleType rf'
            else drf
      | Type rf ->
          let rf' = self#reference_type rf in
            if rf != rf' then Type rf'
            else drf
      | Constructor rf ->
          let rf' = self#reference_constructor rf in
            if rf != rf' then Constructor rf'
            else drf
      | Field rf ->
          let rf' = self#reference_field rf in
            if rf != rf' then Field rf'
            else drf
      | Extension rf ->
          let rf' = self#reference_extension rf in
            if rf != rf' then Extension rf'
            else drf
      | Exception rf ->
          let rf' = self#reference_exception rf in
            if rf != rf' then Exception rf'
            else drf
      | Value rf ->
          let rf' = self#reference_value rf in
            if rf != rf' then Value rf'
            else drf
      | Class rf ->
          let rf' = self#reference_class rf in
            if rf != rf' then Class rf'
            else drf
      | ClassSignature rf ->
          let rf' = self#reference_class_signature rf in
            if rf != rf' then ClassSignature rf'
            else drf
      | Method rf ->
          let rf' = self#reference_method rf in
            if rf != rf' then Method rf'
            else drf
      | InstanceVariable rf ->
          let rf' = self#reference_instance_variable rf in
            if rf != rf' then InstanceVariable rf'
            else drf
      | Element rf ->
          let rf' = self#reference_any rf in
            if rf != rf' then Element rf'
            else drf
      | Section rf ->
          let rf' = self#reference_label rf in
            if rf != rf' then Section rf'
            else drf
      | Link link ->
          let link' = self#documentation_reference_link link in
            if link != link' then Link link'
            else drf
      | Custom(custom, body) ->
          let custom' = self#documentation_reference_custom custom in
          let body' = self#documentation_reference_custom_body body in
            if custom != custom' || body != body' then Custom(custom', body')
            else drf

  method documentation_reference_link link = link
  method documentation_reference_custom custom = custom
  method documentation_reference_custom_body body = body

  method documentation_special sr =
    let open Documentation in
      match sr with
      | Modules rfs ->
          let rfs' = list_map self#reference_module rfs in
            if rfs != rfs' then Modules rfs'
            else sr
      | Index -> sr

  method documentation_see see =
    let open Documentation in
      match see with
      | Url url ->
          let url' = self#documentation_see_url url in
            if url != url' then Url url'
            else see
      | File file ->
          let file' = self#documentation_see_file file in
            if file != file' then File file'
            else see
      | Doc doc ->
          let doc' = self#documentation_see_doc doc in
            if doc != doc' then Doc doc'
            else see

  method documentation_see_url url = url
  method documentation_see_file file = file
  method documentation_see_doc doc = doc

  method documentation_text_element elem =
    let open Documentation in
      match elem with
      | Raw raw ->
          let raw' = self#documentation_text_raw raw in
            if raw != raw' then Raw raw'
            else elem
      | Code code ->
          let code' = self#documentation_text_code code in
            if code != code' then Code code'
            else elem
      | PreCode precode ->
          let precode' = self#documentation_text_precode precode in
            if precode != precode' then PreCode precode'
            else elem
      | Verbatim verbatim ->
          let verbatim' = self#documentation_text_verbatim verbatim in
            if verbatim != verbatim' then Verbatim verbatim'
            else elem
      | Style(style, text) ->
          let style' = self#documentation_style style in
          let text' = self#documentation_text text in
            if style != style' || text != text' then Style(style', text')
            else elem
      | List texts ->
          let texts' = list_map self#documentation_text texts in
            if texts != texts' then List texts'
            else elem
      | Newline -> elem
      | Enum texts ->
          let texts' = list_map self#documentation_text texts in
            if texts != texts' then Enum texts'
            else elem
      | Title(level, label, text) ->
          let level' = self#documentation_text_title_level level in
          let label' = option_map self#identifier_label label in
          let text' = self#documentation_text text in
            if level != level' || label != label' || text != text' then
              Title(level', label', text')
            else elem
      | Reference(rf, text) ->
          let rf' = self#documentation_reference rf in
          let text' = option_map self#documentation_text text in
            if rf != rf' || text != text' then Reference(rf', text')
            else elem
      | Target(target, body) ->
          let target' = self#documentation_text_target target in
          let body' = self#documentation_text_target_body body in
            if target != target' || body != body' then Target(target', body')
            else elem
      | Special sr ->
          let sr' = self#documentation_special sr in
            if sr != sr' then Special sr'
            else elem

  method documentation_text_raw raw = raw
  method documentation_text_code code = code
  method documentation_text_precode precode = precode
  method documentation_text_verbatim verbatim = verbatim
  method documentation_text_title_level level = level
  method documentation_text_target target = target
  method documentation_text_target_body body = body

  method documentation_text text =
    list_map self#documentation_text_element text

  method documentation_tag tag =
    let open Documentation in
      match tag with
      | Author author ->
          let author' = self#documentation_tag_author author in
            if author != author' then Author author'
            else tag
      | Version version ->
          let version' = self#documentation_tag_version version in
            if version != version' then Version version'
            else tag
      | See(see, body) ->
          let see' = self#documentation_see see in
          let body' = self#documentation_tag_see_body body in
            if see != see' || body != body' then See(see', body')
            else tag
      | Since since ->
          let since' = self#documentation_tag_since since in
            if since != since' then Since since'
            else tag
      | Before(before, body) ->
          let before' = self#documentation_tag_before before in
          let body' = self#documentation_tag_before_body body in
            if before != before' || body != body' then Before(before', body')
            else tag
      | Deprecated deprecated ->
          let deprecated' = self#documentation_tag_deprecated deprecated in
            if deprecated != deprecated' then Deprecated deprecated'
            else tag
      | Param(param, body) ->
          let param' = self#documentation_tag_param param in
          let body' = self#documentation_tag_param_body body in
            if param != param' || body != body' then Param(param', body')
            else tag
      | Raise(raise, body) ->
          let raise' = self#documentation_tag_raise raise in
          let body' = self#documentation_tag_raise_body body in
            if raise != raise' || body != body' then Raise(raise', body')
            else tag
      | Return return ->
          let return' = self#documentation_tag_return return in
            if return != return' then Return return'
            else tag
      | Tag(name, body) ->
          let name' = self#documentation_tag_name name in
          let body' = self#documentation_tag_body body in
            if name != name' || body != body' then Tag(name', body')
            else tag

  method documentation_tag_author author = author
  method documentation_tag_version version = version
  method documentation_tag_see_body body = body
  method documentation_tag_since since = since
  method documentation_tag_before before = before
  method documentation_tag_before_body body = body
  method documentation_tag_deprecated deprecated = deprecated
  method documentation_tag_param param = param
  method documentation_tag_param_body body = body
  method documentation_tag_raise raise = raise
  method documentation_tag_raise_body body = body
  method documentation_tag_return return = return
  method documentation_tag_name tag = tag
  method documentation_tag_body body = body

  method documentation_tags tags =
    list_map self#documentation_tag tags

  method documentation doc =
    let open Documentation in
    let {text; tags} = doc in
    let text' = self#documentation_text text in
    let tags' = self#documentation_tags tags in
      if text != text' || tags != tags' then {text = text'; tags = tags'}
      else doc

  method documentation_comment comment =
    let open Documentation in
      match comment with
      | Documentation doc ->
          let doc' = self#documentation doc in
            if doc != doc' then Documentation doc'
            else comment
      | Stop -> comment

end

class virtual ['a] module_ = object (self)

  method virtual identifier_module :
    'a Identifier.module_ -> 'a Identifier.module_

  method virtual path_module :
    'a Path.module_ -> 'a Path.module_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual module_type_expr :
    'a ModuleType.expr -> 'a ModuleType.expr

  method module_decl decl =
    let open Module in
      match decl with
      | Alias p ->
          let p' = self#path_module p in
            if p != p' then Alias p'
            else decl
      | ModuleType expr ->
          let expr' = self#module_type_expr expr in
            if expr != expr' then ModuleType expr'
            else decl

  method module_ md =
    let open Module in
    let {id; doc; type_} = md in
    let id' = self#identifier_module id in
    let doc' = self#documentation doc in
    let type' = self#module_decl type_ in
      if id != id' || doc != doc' || type_ != type' then
        {id = id'; doc = doc'; type_ = type'}
      else md

  method module_equation eq =
    self#module_decl eq

end

class virtual ['a] module_type = object (self)

  method virtual identifier_module :
    'a Identifier.module_ -> 'a Identifier.module_

  method virtual identifier_module_type :
    'a Identifier.module_type -> 'a Identifier.module_type

  method virtual path_module :
    'a Path.module_ -> 'a Path.module_

  method virtual path_module_type :
    'a Path.module_type -> 'a Path.module_type

  method virtual path_type :
    'a Path.type_ -> 'a Path.type_

  method virtual fragment_module :
    Fragment.module_ -> Fragment.module_

  method virtual fragment_type :
    Fragment.type_ -> Fragment.type_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual module_decl :
    'a Module.decl -> 'a Module.decl

  method virtual module_equation :
    'a Module.Equation.t -> 'a Module.Equation.t

  method virtual signature :
    'a Signature.t -> 'a Signature.t

  method virtual type_decl_equation :
    'a TypeDecl.Equation.t -> 'a TypeDecl.Equation.t

  method virtual type_decl_param_name :
    string -> string

  method module_type_substitution subst =
    let open ModuleType in
      match subst with
      | ModuleEq(frag, eq) ->
          let frag' = self#fragment_module frag in
          let eq' = self#module_equation eq in
            if frag != frag' || eq != eq' then ModuleEq(frag', eq')
            else subst
      | TypeEq(frag, eq) ->
          let frag' = self#fragment_type frag in
          let eq' = self#type_decl_equation eq in
            if frag != frag' || eq != eq' then TypeEq(frag', eq')
            else subst
      | ModuleSubst(frag, p) ->
          let frag' = self#fragment_module frag in
          let p' = self#path_module p in
            if frag != frag' || p != p' then
              ModuleSubst(frag', p')
            else subst
      | TypeSubst(frag, params, p) ->
          let frag' = self#fragment_type frag in
          let params' = list_map self#type_decl_param_name params in
          let p' = self#path_type p in
            if frag != frag' || params != params' || p != p' then
              TypeSubst(frag', params', p')
            else subst

  method module_type_expr expr =
    let open ModuleType in
      match expr with
      | Ident p ->
          let p' = self#path_module_type p in
            if p != p' then Ident p'
            else expr
      | Signature sg ->
          let sg' = self#signature sg in
            if sg != sg' then Signature sg'
            else expr
      | Functor(arg, res) ->
          let arg' = self#module_type_functor_arg arg in
          let res' = self#module_type_expr res in
            if arg != arg' || res != res' then Functor(arg', res')
            else expr
      | With(body, substs) ->
          let body' = self#module_type_expr body in
          let substs' = list_map self#module_type_substitution substs in
            if body != body' || substs != substs' then With(body', substs')
            else expr
      | TypeOf decl ->
          let decl' = self#module_decl decl in
            if decl != decl' then TypeOf decl'
            else expr

  method module_type_functor_arg arg =
    match arg with
    | None -> arg
    | Some(id, expr) ->
        let id' = self#identifier_module id in
        let expr' = self#module_type_expr expr in
          if id != id' || expr != expr' then Some(id', expr')
          else arg

  method module_type mty =
    let open ModuleType in
    let {id; doc; expr} = mty in
    let id' = self#identifier_module_type id in
    let doc' = self#documentation doc in
    let expr' = option_map self#module_type_expr expr in
      if id != id' || doc != doc' || expr != expr' then
        {id = id'; doc = doc'; expr = expr'}
      else mty
end

class virtual ['a] signature = object (self)

  method virtual documentation_comment :
    'a Documentation.comment -> 'a Documentation.comment

  method virtual module_ :
    'a Module.t -> 'a Module.t

  method virtual module_type :
    'a ModuleType.t -> 'a ModuleType.t

  method virtual module_type_expr :
    'a ModuleType.expr -> 'a ModuleType.expr

  method virtual type_decl :
    'a TypeDecl.t -> 'a TypeDecl.t

  method virtual extension :
    'a Extension.t -> 'a Extension.t

  method virtual exception_ :
    'a Exception.t -> 'a Exception.t

  method virtual value :
    'a Value.t -> 'a Value.t

  method virtual external_ :
    'a External.t -> 'a External.t

  method virtual class_ :
    'a Class.t -> 'a Class.t

  method virtual class_type :
    'a ClassType.t -> 'a ClassType.t

  method signature_item item =
    let open Signature in
      match item with
      | Value v ->
          let v' = self#value v in
            if v != v' then Value v'
            else item
      | External ve ->
          let ve' = self#external_ ve in
            if ve != ve' then External ve'
            else item
      | Type decl ->
          let decl' = self#type_decl decl in
            if decl != decl' then Type decl'
            else item
      | TypExt ext ->
          let ext' = self#extension ext in
            if ext != ext' then TypExt ext'
            else item
      | Exception exn ->
          let exn' = self#exception_ exn in
            if exn != exn' then Exception exn'
            else item
      | Class cls ->
          let cls' = self#class_ cls in
            if cls != cls' then Class cls'
            else item
      | ClassType clty ->
          let clty' = self#class_type clty in
            if clty != clty' then ClassType clty'
            else item
      | Module md ->
          let md' = self#module_ md in
            if md != md' then Module md'
            else item
      | ModuleType mty ->
          let mty' = self#module_type mty in
            if mty != mty' then ModuleType mty'
            else item
      | Include incl ->
          let incl' = self#module_type_expr incl in
            if incl != incl' then Include incl'
            else item
      | Comment com ->
          let com' = self#documentation_comment com in
            if com != com' then Comment com'
            else item

  method signature sg =
    list_map self#signature_item sg

end

class virtual ['a] type_decl = object (self)

  method virtual identifier_type :
    'a Identifier.datatype -> 'a Identifier.datatype

  method virtual identifier_constructor :
    'a Identifier.constructor -> 'a Identifier.constructor

  method virtual identifier_field :
    'a Identifier.field -> 'a Identifier.field

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method type_decl_constructor cstr =
    let open TypeDecl.Constructor in
    let {id; doc; args; res} = cstr in
    let id' = self#identifier_constructor id in
    let doc' = self#documentation doc in
    let args' = list_map self#type_expr args in
    let res' = option_map self#type_expr res in
      if id != id' || doc != doc' || args != args' || res != res' then
        {id = id'; doc = doc'; args = args'; res = res'}
      else cstr

  method type_decl_field field =
    let open TypeDecl.Field in
    let {id; doc; type_} = field in
    let id' = self#identifier_field id in
    let doc' = self#documentation doc in
    let type' = self#type_expr type_ in
      if id != id' || doc != doc' || type_ != type' then
        {id = id'; doc = doc'; type_ = type'}
      else field

  method type_decl_representation repr =
    let open TypeDecl.Representation in
      match repr with
      | Variant cstrs ->
          let cstrs' = list_map self#type_decl_constructor cstrs in
            if cstrs != cstrs' then Variant cstrs'
            else repr
      | Record fields ->
          let fields' = list_map self#type_decl_field fields in
            if fields != fields' then Record fields'
            else repr
      | Extensible -> repr

  method type_decl_variance variance = variance

  method type_decl_param_desc desc =
    let open TypeDecl in
      match desc with
      | Any -> desc
      | Var name ->
          let name' = self#type_decl_param_name name in
            if name != name' then Var name'
            else desc

  method type_decl_param_name name = name

  method type_decl_param param =
    let desc, var = param in
    let desc' = self#type_decl_param_desc desc in
    let var' = option_map self#type_decl_variance var in
      if desc != desc' || var != var' then (desc', var')
      else param

  method type_decl_equation eq =
    let open TypeDecl.Equation in
    let {params; private_; manifest; constraints} = eq in
    let params' = list_map self#type_decl_param params in
    let private' = self#type_decl_private private_ in
    let manifest' = option_map self#type_expr manifest in
    let constraints' = list_map self#type_decl_constraint constraints in
      if params != params' || private_ != private'
         || manifest != manifest' || constraints != constraints'
      then
        {params = params'; private_ = private';
         manifest = manifest'; constraints = constraints'}
      else eq

  method type_decl_private priv = priv

  method type_decl_constraint cstr =
    let typ1, typ2 = cstr in
    let typ1' = self#type_expr typ1 in
    let typ2' = self#type_expr typ2 in
      if typ1 != typ1' || typ1 != typ1' then (typ1', typ2')
      else cstr

  method type_decl decl =
    let open TypeDecl in
    let {id; doc; equation; representation = repr} = decl in
    let id' = self#identifier_type id in
    let doc' = self#documentation doc in
    let equation' = self#type_decl_equation equation in
    let repr' =
      option_map self#type_decl_representation repr
    in
      if id != id' || doc != doc'
         || equation != equation' || repr != repr'
      then
        {id = id'; doc = doc';
         equation = equation'; representation = repr'}
      else decl

end

class virtual ['a] extension = object (self)

  method virtual identifier_extension :
    'a Identifier.extension -> 'a Identifier.extension

  method virtual path_type :
    'a Path.type_ -> 'a Path.type_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_decl_param :
    TypeDecl.param -> TypeDecl.param

  method virtual type_decl_private :
    bool -> bool

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method extension_constructor cstr =
    let open Extension.Constructor in
    let {id; doc; args; res} = cstr in
    let id' = self#identifier_extension id in
    let doc' = self#documentation doc in
    let args' = list_map self#type_expr args in
    let res' = option_map self#type_expr res in
      if id != id' || doc != doc' || args != args' || res != res' then
        {id = id'; doc = doc'; args = args'; res = res'}
      else cstr

  method extension ext =
    let open Extension in
    let {type_path; doc; type_params; private_; constructors} = ext in
    let type_path' = self#path_type type_path in
    let doc' = self#documentation doc in
    let type_params' = list_map self#type_decl_param type_params in
    let private' = self#type_decl_private private_ in
    let constructors' = list_map self#extension_constructor constructors in
      if type_path != type_path' || doc != doc' || type_params != type_params'
         || private_ != private' || constructors != constructors'
      then
        {type_path = type_path'; doc = doc'; type_params = type_params';
         private_ = private'; constructors = constructors'}
      else ext

end

class virtual ['a] exception_ = object (self)

  method virtual identifier_exception :
    'a Identifier.exception_ -> 'a Identifier.exception_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method exception_ exn =
    let open Exception in
    let {id; doc; args; res} = exn in
    let id' = self#identifier_exception id in
    let doc' = self#documentation doc in
    let args' = list_map self#type_expr args in
    let res' = option_map self#type_expr res in
      if id != id' || doc != doc' || args != args' || res != res' then
        {id = id'; doc = doc'; args = args'; res = res'}
      else exn

end

class virtual ['a] value = object (self)

  method virtual identifier_value :
    'a Identifier.value -> 'a Identifier.value

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method value v =
    let open Value in
    let {id; doc; type_} = v in
    let id' = self#identifier_value id in
    let doc' = self#documentation doc in
    let type' = self#type_expr type_ in
      if id != id' || doc != doc' || type_ != type' then
        {id = id'; doc = doc'; type_ = type'}
      else v

end

class virtual ['a] external_ = object (self)

  method virtual identifier_value :
    'a Identifier.value -> 'a Identifier.value

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method external_ ve =
    let open External in
    let {id; doc; type_; primitives} = ve in
    let id' = self#identifier_value id in
    let doc' = self#documentation doc in
    let type' = self#type_expr type_ in
    let primitives' = list_map self#external_primitive primitives in
      if id != id' || doc != doc'
         || type_ != type' || primitives != primitives'
      then
        {id = id'; doc = doc'; type_ = type'; primitives = primitives'}
      else ve

  method external_primitive prim = prim

end

class virtual ['a] class_ = object (self)

  method virtual identifier_class :
    'a Identifier.class_ -> 'a Identifier.class_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_decl_param :
    TypeDecl.param -> TypeDecl.param

  method virtual class_type_expr :
    'a ClassType.expr -> 'a ClassType.expr

  method virtual type_expr_label :
    TypeExpr.label -> TypeExpr.label

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method class_decl decl =
    let open Class in
      match decl with
      | ClassType expr ->
          let expr' = self#class_type_expr expr in
            if expr != expr' then ClassType expr'
            else decl
      | Arrow(lbl, typ, body) ->
          let lbl' = option_map self#type_expr_label lbl in
          let typ' = self#type_expr typ in
          let body' = self#class_decl body in
            if lbl != lbl' || typ != typ' || body != body' then
              Arrow(lbl', typ', body')
            else decl

  method class_ cls =
    let open Class in
    let {id; doc; virtual_; params; type_} = cls in
    let id' = self#identifier_class id in
    let doc' = self#documentation doc in
    let virtual' = self#class_virtual virtual_ in
    let params' = list_map self#type_decl_param params in
    let type' = self#class_decl type_ in
      if id != id' || doc != doc' || virtual_ != virtual'
         || params != params' || type_ != type'
      then
        {id = id'; doc = doc'; virtual_ = virtual';
         params = params'; type_ = type'}
      else cls

  method class_virtual virt = virt

end

class virtual ['a] class_type = object (self)

  method virtual identifier_class_type :
    'a Identifier.class_type -> 'a Identifier.class_type

  method virtual path_class_signature :
    'a Path.class_signature -> 'a Path.class_signature

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_decl_param :
    TypeDecl.param -> TypeDecl.param

  method virtual class_signature :
    'a ClassSignature.t -> 'a ClassSignature.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method class_type_expr expr =
    let open ClassType in
      match expr with
      | Constr(p, params) ->
          let p' = self#path_class_signature p in
          let params' = list_map self#type_expr params in
            if p != p' || params != params' then Constr(p', params')
            else expr
      | Signature csig ->
          let csig' = self#class_signature csig in
            if csig != csig' then Signature csig'
            else expr

  method class_type clty =
    let open ClassType in
    let {id; doc; virtual_; params; expr} = clty in
    let id' = self#identifier_class_type id in
    let doc' = self#documentation doc in
    let virtual' = self#class_type_virtual virtual_ in
    let params' = list_map self#type_decl_param params in
    let expr' = self#class_type_expr expr in
      if id != id' || doc != doc' || virtual_ != virtual'
         || params != params' || expr != expr'
      then
        {id = id'; doc = doc'; virtual_ = virtual';
         params = params'; expr = expr'}
      else clty

  method class_type_virtual virt = virt

end

class virtual ['a] class_signature = object (self)

  method virtual documentation_comment :
    'a Documentation.comment -> 'a Documentation.comment

  method virtual class_type_expr :
    'a ClassType.expr -> 'a ClassType.expr

  method virtual method_ :
    'a Method.t -> 'a Method.t

  method virtual instance_variable :
    'a InstanceVariable.t -> 'a InstanceVariable.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method class_signature_item item =
    let open ClassSignature in
      match item with
      | InstanceVariable inst ->
          let inst' = self#instance_variable inst in
            if inst != inst' then InstanceVariable inst'
            else item
      | Method meth ->
          let meth' = self#method_ meth in
            if meth != meth' then Method meth'
            else item
      | Constraint(typ1, typ2) ->
          let typ1' = self#type_expr typ1 in
          let typ2' = self#type_expr typ2 in
            if typ1 != typ1' || typ1 != typ1' then Constraint(typ1', typ2')
            else item
      | Inherit expr ->
          let expr' = self#class_type_expr expr in
            if expr != expr' then Inherit expr'
            else item
      | Comment com ->
          let com' = self#documentation_comment com in
            if com != com' then Comment com'
            else item

  method class_signature csig =
    let open ClassSignature in
    let {self = slf; items} = csig in
    let slf' = option_map self#type_expr slf in
    let items' = list_map self#class_signature_item items in
      if slf != slf' || items != items' then
        {self = slf'; items = items'}
      else csig

end

class virtual ['a] method_ = object (self)

  method virtual identifier_method :
    'a Identifier.method_ -> 'a Identifier.method_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method method_ meth =
    let open Method in
    let {id; doc; private_; virtual_; type_} = meth in
    let id' = self#identifier_method id in
    let doc' = self#documentation doc in
    let private' = self#method_private private_ in
    let virtual' = self#method_virtual virtual_ in
    let type' = self#type_expr type_ in
      if id != id' || doc != doc' || private_ != private'
         || virtual_ != virtual' || type_ != type'
      then
        {id = id'; doc = doc'; private_ = private';
         virtual_ = virtual'; type_ = type'}
      else meth

  method method_private priv = priv

  method method_virtual virt = virt

end

class virtual ['a] instance_variable = object (self)

  method virtual identifier_instance_variable :
    'a Identifier.instance_variable -> 'a Identifier.instance_variable

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual type_expr :
    'a TypeExpr.t -> 'a TypeExpr.t

  method instance_variable meth =
    let open InstanceVariable in
    let {id; doc; mutable_; virtual_; type_} = meth in
    let id' = self#identifier_instance_variable id in
    let doc' = self#documentation doc in
    let mutable' = self#instance_variable_mutable mutable_ in
    let virtual' = self#instance_variable_virtual virtual_ in
    let type' = self#type_expr type_ in
      if id != id' || doc != doc' || mutable_ != mutable'
         || virtual_ != virtual' || type_ != type'
      then
        {id = id'; doc = doc'; mutable_ = mutable';
         virtual_ = virtual'; type_ = type'}
      else meth

  method instance_variable_mutable mut = mut

  method instance_variable_virtual virt = virt

end

class virtual ['a] type_expr = object (self)

  method virtual path_module_type :
    'a Path.module_type -> 'a Path.module_type

  method virtual path_type :
    'a Path.type_ -> 'a Path.type_

  method virtual path_class_signature :
    'a Path.class_signature -> 'a Path.class_signature

  method virtual fragment_type :
    Fragment.type_ -> Fragment.type_

  method type_expr_variant_kind kind = kind

  method type_expr_variant_element elem =
    let open TypeExpr.Variant in
      match elem with
      | Type typ ->
          let typ' = self#type_expr typ in
            if typ != typ' then Type typ'
            else elem
      | Constructor(name, const, args) ->
          let name' = self#type_expr_variant_constructor_name name in
          let const' = self#type_expr_variant_constructor_const const in
          let args' = list_map self#type_expr args in
            if name != name' || const != const' || args != args' then
              Constructor(name', const', args')
            else elem

  method type_expr_variant_constructor_name name = name

  method type_expr_variant_constructor_const const = const

  method type_expr_variant var =
    let open TypeExpr.Variant in
    let {kind; elements} = var in
    let kind' = self#type_expr_variant_kind kind in
    let elements' = list_map self#type_expr_variant_element elements in
      if kind != kind' || elements != elements' then
        {kind = kind'; elements = elements'}
      else var

  method type_expr_object_method meth =
    let open TypeExpr.Object in
    let {name; type_} = meth in
    let name' = self#type_expr_object_method_name name in
    let type' = self#type_expr type_ in
      if name != name' || type_ != type' then
        {name = name'; type_ = type'}
      else meth

  method type_expr_object_method_name name = name

  method type_expr_object obj =
    let open TypeExpr.Object in
    let {methods; open_} = obj in
    let methods' = list_map self#type_expr_object_method methods in
    let open' = self#type_expr_object_open open_ in
      if methods != methods' || open_ != open' then
        {methods = methods'; open_ = open'}
      else obj

  method type_expr_object_open opn = opn

  method type_expr_package_substitution subst =
    let frag, typ = subst in
    let frag' = self#fragment_type frag in
    let typ' = self#type_expr typ in
      if frag != frag' || typ != typ' then (frag', typ')
      else subst

  method type_expr_package pkg =
    let open TypeExpr.Package in
    let {path; substitutions = substs} = pkg in
    let path' = self#path_module_type path in
    let substs' = list_map self#type_expr_package_substitution substs in
      if path != path' || substs != substs' then
        {path = path'; substitutions = substs'}
      else pkg

  method type_expr_label lbl =
    let open TypeExpr in
      match lbl with
      | Label name ->
          let name' = self#type_expr_label_name name in
            if name != name' then Label name'
            else lbl
      | Optional name ->
          let name' = self#type_expr_label_name name in
            if name != name' then Optional name'
            else lbl

  method type_expr_label_name name = name

  method type_expr typ =
    let open TypeExpr in
      match typ with
      | Var name ->
          let name' = self#type_expr_var_name name in
            if name != name' then Var name'
            else typ
      | Any -> typ
      | Alias(body, name) ->
          let body' = self#type_expr body in
          let name' = self#type_expr_var_name name in
            if body != body' || name != name' then Alias(body', name')
            else typ
      | Arrow(lbl, arg, res) ->
          let lbl' = option_map self#type_expr_label lbl in
          let arg' = self#type_expr arg in
          let res' = self#type_expr res in
            if lbl != lbl' || arg != arg' || res != res' then Arrow(lbl', arg', res')
            else typ
      | Tuple typs ->
          let typs' = list_map self#type_expr typs in
            if typs != typs' then Tuple typs'
            else typ
      | Constr(p, params) ->
          let p' = self#path_type p in
          let params' = list_map self#type_expr params in
            if p != p' || params != params' then Constr(p', params')
            else typ
      | Variant var ->
          let var' = self#type_expr_variant var in
            if var != var' then Variant var'
            else typ
      | Object obj ->
          let obj' = self#type_expr_object obj in
            if obj != obj' then Object obj'
            else typ
      | Class(p, params) ->
          let p' = self#path_class_signature p in
          let params' = list_map self#type_expr params in
            if p != p' || params != params' then Class(p', params')
            else typ
      | Poly(vars, body) ->
          let vars' = list_map self#type_expr_var_name vars in
          let body' = self#type_expr body in
            if vars != vars' || body != body' then Poly(vars', body')
            else typ
      | Package pkg ->
          let pkg' = self#type_expr_package pkg in
            if pkg != pkg' then Package pkg'
            else typ

  method type_expr_var_name name = name

end

class virtual ['a] unit = object (self)

  method virtual root : 'a -> 'a

  method virtual identifier_module :
    'a Identifier.module_ -> 'a Identifier.module_

  method virtual documentation :
    'a Documentation.t -> 'a Documentation.t

  method virtual signature :
    'a Signature.t -> 'a Signature.t

  method unit_import import =
    let open Unit in
      match import with
      | Unresolved(name, digest) ->
          let name' = self#unit_import_name name in
          let digest' = option_map self#unit_digest digest in
            if name != name' || digest != digest' then
              Unresolved(name', digest')
            else import
      | Resolved r ->
          let r' = self#root r in
            if r != r' then Resolved r'
            else import

  method unit_import_name name = name

  method unit_digest digest = digest

  method unit unit =
    let open Unit in
    let {id; doc; digest; imports; items} = unit in
    let id' = self#identifier_module id in
    let doc' = self#documentation doc in
    let digest' = self#unit_digest digest in
    let imports' = list_map self#unit_import imports in
    let items' = self#signature items in
      if id != id' || doc != doc' || digest != digest'
         || imports != imports' || items != items'
      then
        {id = id'; doc = doc'; digest = digest';
         imports = imports'; items = items'}
      else unit

end

class virtual ['a] types = object
  inherit ['a] documentation
  inherit ['a] module_
  inherit ['a] module_type
  inherit ['a] signature
  inherit ['a] type_decl
  inherit ['a] extension
  inherit ['a] exception_
  inherit ['a] value
  inherit ['a] external_
  inherit ['a] class_
  inherit ['a] class_type
  inherit ['a] class_signature
  inherit ['a] method_
  inherit ['a] instance_variable
  inherit ['a] type_expr
  inherit ['a] unit
end
