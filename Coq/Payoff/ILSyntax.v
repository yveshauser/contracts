Add LoadPath "..".

Require Import Reals Syntax.

Inductive ILBinOp : Set := ILAdd | ILSub | ILMult | ILDiv | ILAnd | ILOr |
                           ILLess | ILLeq | ILEqual.

Inductive ILUnOp : Set := ILNot | ILNeg.


Inductive ILExpr : Set :=
| ILIf : ILExpr -> ILExpr -> ILExpr -> ILExpr
| FloatV : R -> ILExpr
| Model : ObsLabel -> Z -> ILExpr
| ILUnExpr : ILUnOp -> ILExpr -> ILExpr
| ILBinExpr : ILBinOp -> ILExpr -> ILExpr -> ILExpr
| Payoff  : nat -> Party -> Party -> ILExpr. 