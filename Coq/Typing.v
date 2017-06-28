(********** Typing Rules **********)

Require Export Syntax.

Import ListNotations.

(* Types for the expression language *)
Inductive Ty := REAL | BOOL.


(* Typing of operations *)

Reserved Notation "'|-Op' e '∶' t '=>' r" (at level 20).

Inductive TypeOp : Op -> list Ty -> Ty -> Prop := 
| type_blit b : |-Op (BLit b) ∶ [] => BOOL
| type_rlit r : |-Op (RLit r) ∶ [] => REAL
| type_neg : |-Op Neg ∶ [REAL] => REAL
| type_not : |-Op Not ∶ [BOOL] => BOOL
| type_cond t : |-Op Cond ∶ [BOOL;t;t] => t
| type_add : |-Op Add ∶ [REAL;REAL] => REAL
| type_sub : |-Op Sub ∶ [REAL;REAL] => REAL
| type_mult : |-Op Mult ∶ [REAL;REAL] => REAL
| type_div : |-Op Div ∶ [REAL;REAL] => REAL
| type_and : |-Op And ∶ [BOOL;BOOL] => BOOL
| type_or : |-Op Or ∶ [BOOL;BOOL] => BOOL
| type_less : |-Op Less ∶ [REAL;REAL] => BOOL
| type_leq : |-Op Leq ∶ [REAL;REAL] => BOOL
| type_equal : |-Op Equal ∶ [REAL;REAL] => BOOL
        where "'|-Op' v '∶' t '=>' r" := (TypeOp v t r).


(* Typing of observalbes *)
Reserved Notation "'|-O' e '∶' t" (at level 20).

Inductive TypeObs : ObsLabel -> Ty -> Prop := 
| type_obs_bool b : |-O LabB b ∶ BOOL
| type_obs_real b : |-O LabR b ∶ REAL
        where "'|-O' v '∶' t" := (TypeObs v t).


(* Type environments map variables to their types. *)

Definition TyEnv := list Ty.

(* Typing of variables *)

Reserved Notation "g '|-X' v '∶' t" (at level 20).

Inductive TypeVar : TyEnv -> Var -> Ty -> Prop :=
| type_var_1 t g  : (t :: g) |-X V1 ∶ t
| type_var_S g v t t' : g |-X v ∶ t -> (t' :: g) |-X VS v ∶ t
        where "g '|-X' v '∶' t" := (TypeVar g v t).


(* Typing of expressions *)

Reserved Notation "g '|-E' e '∶' t" (at level 20).

Inductive TypeExp : TyEnv -> Exp -> Ty -> Prop :=
| type_op g op es ts t : |-Op op ∶ ts => t -> all2 (TypeExp g) es ts -> g |-E OpE op es ∶ t
| type_obs t g o z : |-O o ∶ t -> g |-E Obs o z ∶ t
| type_var t g v : g |-X v ∶ t -> g |-E VarE v ∶ t
| type_acc n t g e1 e2 : (t :: g) |-E e1 ∶ t -> g |-E e2 ∶ t -> g |-E Acc e1 n e2 ∶ t
        where "g '|-E' e '∶' t" := (TypeExp g e t).

(* The induction principle generated by Coq is not strong enough. We
need to roll our own. *)

Definition TypeExp_ind' : forall P : TyEnv -> Exp -> Ty -> Prop,
       (forall (g : TyEnv) (op : Op) (es : list Exp) (ts : list Ty) (t : Ty),
        |-Op op ∶ ts => t ->
        all2 (TypeExp g) es ts -> all2 (P g) es ts -> P g (OpE op es) t) ->
       (forall (t : Ty) (g : TyEnv) (o : ObsLabel) (z : Z),
        |-O o ∶ t -> P g (Obs o z) t) ->
       (forall (t : Ty) (g : TyEnv) (v : Var), g |-X v ∶ t -> P g (VarE v) t) ->
       (forall (n : nat) (t : Ty) (g : list Ty) (e1 e2 : Exp),
        (t :: g) |-E e1 ∶ t ->
        P (t :: g) e1 t -> g |-E e2 ∶ t -> P g e2 t -> P g (Acc e1 n e2) t) ->
       forall (t : TyEnv) (e : Exp) (t0 : Ty), t |-E e ∶ t0 -> P t e t0 :=
  fun (P : TyEnv -> Exp -> Ty -> Prop)
  (f : forall (g : TyEnv) (op : Op) (es : list Exp) (ts : list Ty) (t : Ty),
       |-Op op ∶ ts => t -> all2 (TypeExp g) es ts -> all2 (P g) es ts -> P g (OpE op es) t)
  (f0 : forall (t : Ty) (g : TyEnv) (o : ObsLabel) (z : Z),
        |-O o ∶ t -> P g (Obs o z) t)
  (f1 : forall (t : Ty) (g : TyEnv) (v : Var), g |-X v ∶ t -> P g (VarE v) t)
  (f2 : forall (n : nat) (t : Ty) (g : list Ty) (e1 e2 : Exp),
        (t :: g) |-E e1 ∶ t ->
        P (t :: g) e1 t -> g |-E e2 ∶ t -> P g e2 t -> P g (Acc e1 n e2) t) =>
fix F (t : TyEnv) (e : Exp) (t0 : Ty) (t1 : t |-E e ∶ t0) {struct t1} :
  P t e t0 :=
  match t1 in (t2 |-E e0 ∶ t3) return (P t2 e0 t3) with
  | type_op g op es ts t2 t3 f3 =>
    let fix step es ts (args: all2 (TypeExp g) es ts) :=
        match args with
          | all2_nil _ => all2_nil (P g)
          | @all2_cons _ _ _ e t0 es ts ty tys => all2_cons (P g) (F g e t0 ty) (step es ts tys)
        end
          in f g op es ts t2 t3 f3 (step es ts f3)
  | type_obs t2 g o z t3 => f0 t2 g o z t3
  | type_var t2 g v t3 => f1 t2 g v t3
  | type_acc n t2 g e1 e2 t3 t4 =>
      f2 n t2 g e1 e2 t3 (F (t2 :: g) e1 t2 t3) t4 (F g e2 t2 t4)
  end.


(* Typing of contracts. *)

Reserved Notation "g '|-C' e" (at level 20).

Inductive TypeContr : TyEnv -> Contr -> Prop :=
| type_zero g : g |-C Zero
| type_let e c t g : g |-E e ∶ t -> (t :: g) |-C c -> g |-C Let e c
| type_transfer p1 p2 c g : g |-C Transfer p1 p2 c
| type_scale e c g : g |-E e ∶ REAL -> g |-C c -> g |-C Scale e c
| type_translate d c g : g |-C c -> g |-C Translate d c
| type_both c1 c2 g : g |-C c1 -> g |-C c2 -> g |-C Both c1 c2
| type_if e d c1 c2 g : g |-E e ∶ BOOL -> g |-C c1 -> g |-C c2 -> g |-C If e d c1 c2
  where "g '|-C' c" := (TypeContr g c).


Hint Constructors TypeOp TypeObs TypeExp TypeVar TypeContr.
