-- Generic pricing
-- ==
-- compiled input @ OptionPricing-data/small.in
-- output @ OptionPricing-data/small.out
--
-- compiled input @ OptionPricing-data/medium.in
-- output @ OptionPricing-data/medium.out
--
-- compiled input @ OptionPricing-data/large.in
-- output @ OptionPricing-data/large.out

import "/futlib/math"
import "/futlib/array"
import "Price"

default(f32)

let trajInner(amount: f32, ind: i32, disc: []f32): f32 = amount * unsafe disc[ind]

let fminPayoff(xs: []f32): f32 =
  --    MIN( map(/, xss, {3758.05, 11840.0, 1200.0}) )
  let (a,b,c) = ( xs[0]/3758.05, xs[1]/11840.0, xs[2]/1200.0)
  in if a < b
     then if a < c then a else c
     else if b < c then b else c

let payoff1(md_disct: []f32, md_detval: []f32, xss: [1][1]f32): f32 =
  let detval = unsafe md_detval[0]
  let amount = ( xss[0,0] - 4000.0 ) * detval
  let amount0= if (0.0 < amount) then amount else 0.0
  in  trajInner(amount0, 0, md_disct)

let payoff2 (md_disc: []f32, xss: [5][3]f32): f32 =
  let (date, amount) =
    if      (1.0 <= fminPayoff(xss[0])) then (0, 1150.0)
    else if (1.0 <= fminPayoff(xss[1])) then (1, 1300.0)
    else if (1.0 <= fminPayoff(xss[2])) then (2, 1450.0)
    else if (1.0 <= fminPayoff(xss[3])) then (3, 1600.0)
    else let x50  = fminPayoff(xss[4])
         let value  = if      1.0 <= x50 then 1750.0
                      else if 0.75 < x50 then 1000.0
                      else                    x50*1000.0
         in (4, value)
         in trajInner(amount, date, md_disc)

let payoff3(md_disct: []f32, xss: [367][3]f32): f32 =
  let conds  = map (\x ->
                      x[0] <= 2630.6349999999998 ||
                      x[1] <= 8288.0             ||
                      x[2] <=  840.0)
                   xss
  let cond  = or conds
  let price1= trajInner(100.0,  0, md_disct)
  let goto40= cond && ( xss[366,0] < 3758.05 ||
                        xss[366,1] < 11840.0 ||
                        xss[366,2] < 1200.0)
  let amount= if goto40
              then 1000.0 * fminPayoff(xss[366])
              else 1000.0
  let price2 = trajInner(amount, 1, md_disct)
  in price1 + price2

module Payoff1 = { let payoff x y z = payoff1(x, y, z) }
module Payoff2 = { let payoff x _ z = payoff2(x, z) }
module Payoff3 = { let payoff x _ z = payoff3(x, z) }

module P1 = Price Payoff1
module P2 = Price Payoff2
module P3 = Price Payoff3

-- Entry point
let main [num_bits][num_models][num_und][num_dates]
        (contract_number: i32,
         num_mc_it: i32,
         dir_vs: [][num_bits]i32,
         md_cs: [num_models][num_und][num_und]f32,
         md_vols: [num_models][num_dates][num_und]f32,
         md_drifts: [num_models][num_dates][num_und]f32,
         md_sts: [num_models][num_und]f32,
         md_detvals: [num_models][]f32,
         md_discts: [num_models][]f32,
         bb_inds: [3][num_dates]i32,
         bb_data: [3][num_dates]f32)
         : []f32 =
  let r = {num_mc_it,dir_vs,md_cs,md_vols,md_drifts,md_sts,md_detvals,md_discts,bb_inds,bb_data}
  in if contract_number == 1 then P1.price r
     else if contract_number == 2 then P2.price r
     else if contract_number == 3 then P3.price r
     else []
