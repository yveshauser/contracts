Require Export Denotational.
Require Import TranslateExp.
Require Import FunctionalExtensionality.
Require Import Tactics Utils.

Require Import DenotationalTyped.

(********** Equivalence of contracts **********)

(* Full equivalence. *)

Definition equiv (g : TyEnv) (tenv : TEnv) (c1 c2 : Contr) : Prop
  := g |-C c1 /\ g |-C c2 /\ 
    (forall (env : Env) (ext : ExtEnv), 
      TypeExt ext -> TypeEnv g env -> C[|c1|]env ext tenv = C[|c2|]env ext tenv).
Notation "c1 '≡[' g ',' tenv ']' c2" := (equiv g tenv c1 c2) (at level 50).


Lemma equiv_typed g c1 c2 tenv:
  g |-C c1 ->
  g |-C c2 ->
      (forall t1 t2 env ext,
         TypeExt ext -> TypeEnv g env -> C[|c1|]env ext tenv = Some t1 -> C[|c2|]env ext tenv = Some t2 -> t1 = t2) ->
  c1 ≡[g,tenv] c2.
Proof. 
  intros T1 T2 E. unfold equiv. repeat split;auto. intros. 
  eapply Csem_typed_total in T1;eauto. destruct T1 as [t1 T1].
  eapply Csem_typed_total in T2;eauto. destruct T2 as [t2 T2].
  rewrite T1. rewrite T2. f_equal. eauto.
Qed.

Lemma delay_trace_at d t : delay_trace d t d = t O.
Proof.
  unfold delay_trace. 
  assert (leb d d = true) as E by (apply leb_correct; auto).
  rewrite E. rewrite minus_diag. reflexivity.
Qed.

Hint Resolve translateExp_type.
Theorem transl_ifwithin g e d t c1 c2 tenv n : g |-C c1 -> g |-C c2 -> g |-E e ∶ BOOL -> TexprSem t tenv = n ->
  If (translateExp (Z.of_nat (TexprSem d tenv)) e) t (Translate d c1) (Translate d c2) ≡[g,tenv]
  Translate d (If e t c1 c2).
Proof.
  unfold equiv. intros. repeat split; eauto. intros env ext R V.    
  generalize dependent tenv.
  generalize dependent d.  
  generalize dependent ext.
  generalize dependent t.
  induction n; intros.
  - eapply Esem_typed_total with (ext:=(adv_ext (Z.of_nat (TexprSem d tenv)) ext)) in H1;eauto.
    decompose [ex and] H1. simpl in *. erewrite H2. simpl. rewrite translateExp_ext, H4 in *.
    destruct x. destruct b; reflexivity. reflexivity.
  - pose H1 as H1'. eapply Esem_typed_total with (ext:=(adv_ext (Z.of_nat (TexprSem d tenv)) ext)) in H1';eauto.
    decompose [ex and] H1'. simpl in *. rewrite H2. simpl.
    rewrite translateExp_ext, H4. destruct x; try reflexivity. destruct b. reflexivity.
    specialize IHn with (ext := adv_ext 1 ext) (t:=Tnum n). simpl in IHn.
    rewrite IHn;eauto. rewrite adv_ext_swap. repeat rewrite liftM_liftM. apply liftM_ext. 
    intros. unfold compose. apply delay_trace_swap. 
Qed.

Theorem transl_iter (tenv : TEnv) (c : Contr) t1 t2 (env : Env) (ext : ExtEnv) :
  C[|Translate (Tnum t1) (Translate (Tnum t2) c)|]env ext tenv =
  C[|Translate (Tnum (t1 + t2)) c|]env ext tenv.
Proof.
  simpl. unfold liftM,compose,pure,bind.
  rewrite adv_ext_iter.
  replace (Z.of_nat t1 + Z.of_nat t2)%Z with (Z.of_nat (t1 + t2)) by (symmetry; apply of_nat_plus).
  remember (C[| c|] env (adv_ext (Z.of_nat (t1 + t2)) ext) tenv) as Cs.
  destruct Cs;auto.
  rewrite delay_trace_iter. rewrite plus_comm. reflexivity.
Qed.
