Require Import Denotational.
Require Import Tactics.

(* Definition of contract horizon and proof of its correctness. *)

(* Behaves as addition unless second argument is 0, in which case 0 is
returned. *)

Definition plus0 (n m : nat) : nat :=
  match m with
    | 0 => 0
    | _ => n + m
  end.

Lemma plus0_max_l n m p i : plus0 p (max n m) <= i -> n <= i.
Proof.
  remember (max n m) as h. destruct h. destruct n.  simpl. auto.
  simpl in *. destruct m;tryfalse.
  simpl. rewrite Heqh. intros. assert (max n m <= i) by omega. eapply Max.max_lub_l. eauto.
Qed.

Lemma plus0_max_r n m p i : plus0 p (max n m) <= i -> m <= i.
Proof.
  rewrite Max.max_comm. apply plus0_max_l.
Qed.

Lemma plus0_le n m i : plus0 (S n) m <= i -> plus0 n m <= i - 1.
Proof.
  destruct m. simpl. intros. omega.
  simpl. intros. omega.
Qed.


Fixpoint horizon (c : Contr) (tenv : TEnv): nat :=
  match c with
      | Zero => 0
      | Let _ c' => horizon c' tenv
      | Transfer _ _ _ => 1
      | Scale _ c' => horizon c' tenv
      | Translate v c' => plus0 (TexprSem v tenv) (horizon c' tenv)
      | Both c1 c2 => max (horizon c1 tenv) (horizon c2 tenv)
      | If _ l c1 c2 => plus0 (TexprSem l tenv) (max (horizon c1 tenv) (horizon c2 tenv))
  end.


Lemma max0 n m : max n m = 0 -> n = 0 /\ m = 0.
Proof.
  intros. split. 
  - destruct n. reflexivity. destruct m; simpl in H; inversion H.
  - destruct m. reflexivity. destruct n; simpl in H; inversion H.
Qed.


Theorem horizon_sound c env ext i t tenv: horizon c tenv <= i ->
                                     C[|c|] env ext tenv = Some t -> t i = empty_trans.

Proof.
  intros HO T. generalize dependent env. generalize dependent ext. generalize dependent t.
  generalize dependent i.
  induction c; simpl in *;intros.
  - inversion T. reflexivity.
  - destruct (E[|e|] env ext);tryfalse. simpl in T. eapply IHc. assumption.  eapply T.
  - destruct i. inversion HO. inversion T. reflexivity.
  - remember (E[|e|] env ext >>= toReal) as r. remember (C[|c|] env ext tenv) as C.
    destruct r;destruct C; tryfalse. simpl in T. unfold pure, compose in *. inversion T.
    symmetry in HeqC. eapply IHc with (i:=i) in HeqC ; auto. unfold scale_trace, compose.
    rewrite HeqC. apply scale_empty_trans. 
  - remember (C[|c|] env (adv_ext (Z.of_nat (TexprSem t tenv)) ext) tenv) as C. destruct C;tryfalse.
    simpl in T. unfold pure,compose in T. inversion T. clear T. unfold delay_trace.
    remember (horizon c tenv) as h. destruct h.  
    destruct (leb (TexprSem t tenv) i). eapply IHc. omega. eauto. reflexivity.
    simpl in HO. remember (TexprSem t tenv) as n0. assert (horizon c tenv <= i - n0) as H' by omega.
    rewrite Heqh in *. eapply IHc in H'. 
    unfold delay_trace. assert (leb n0 i = true) as L. apply leb_correct. omega. rewrite L.
    destruct H'; eauto. eauto. 
  - rewrite Nat.max_lub_iff in HO. destruct HO as [H1 H2].
    remember (C[|c1|] env ext tenv) as C1. remember (C[|c2|] env ext tenv) as C2.
    destruct C1; destruct C2; tryfalse.
    simpl in T. unfold pure, compose in T. inversion T.
    unfold add_trace. erewrite IHc1;eauto. erewrite IHc2;eauto.
  - generalize dependent ext. generalize dependent i.
    generalize dependent t0. (*remember (Z.to_nat (TexprSem t tenv)) as n0.*)
    induction (TexprSem t tenv);intros.
    + simpl in HO. simpl in T. destruct (E[|e|] env ext);tryfalse. destruct v;tryfalse.
      destruct b. eapply IHc1; eauto. eapply plus0_max_l; eauto.
      eapply IHc2; eauto. eapply plus0_max_r; eauto.
    + simpl in HO. simpl in T. destruct (E[|e|] env ext);tryfalse. destruct v;tryfalse.
      destruct b. eapply IHc1; eauto. eapply plus0_max_l; eauto.
      remember (within_sem C[|c1|] C[|c2|] e n env (adv_ext 1 ext) tenv) as C. destruct C;tryfalse.
      simpl in T. unfold pure, compose in T. inversion T. clear T.
      symmetry in HeqC. eapply IHn in HeqC. unfold delay_trace. destruct (leb 1 i).
      apply HeqC. reflexivity. apply plus0_le. assumption.
Qed.
