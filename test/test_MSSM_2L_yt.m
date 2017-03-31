Needs["TestSuite`", "TestSuite.m"];
Get[FileNameJoin[{"meta", "TwoLoopMSSM.m"}]];

t2l    = Get[FileNameJoin[{"meta", "MSSM", "tquark_2loop_strong.m"}]];
t2lqcd = Get[FileNameJoin[{"meta", "MSSM", "tquark_2loop_qcd.m"}]] /. GSY -> GS;
DmtOverMtSUSYUniversal = GetDeltaMPoleOverMRunningMSSMSQCDDRbar2LUniversalMSUSY[];

colorCA = 3; colorCF = 4/3; Tf = 1/2; GS = g3;
MGl = mgl; MT = mt; SX = 2 mt Xt; s2t = SX / (mmst1 - mmst2);
fin[0, args__] := fin[args, mmu];

CollectTerms[expr_] := Collect[expr /. zt2 -> Zeta[2], {Log[__]}, Together];

loopFunctions = {
    Hmine[mm1_,mm2_] :> 2 * PolyLog[2, 1-mm1/mm2] + 1/2 * Log[mm1/mm2]^2,
    fin[mm1_,mm2_,mmu_] :>
       1/2 * ( - (mm1 + mm2) * ( 7 + Zeta[2] )
               + 6 * (mm1 * Log[mm1/mmu] + mm2 * Log[mm2/mmu])
               - 2 * (mm1 * Log[mm1/mmu]^2 + mm2 * Log[mm2/mmu]^2 )
               +1/2 * (mm1 + mm2) * Log[mm1/mm2]^2 + (mm1-mm2)*Hmine[mm1,mm2] )
};

(* ******* calculate limit ******* *)

t2lLimitS1S2MSMG = CollectTerms @ Normal[Series[(t2l - t2lqcd) //. loopFunctions //. {
    mmst1  -> mmsusy + x * dst1,
    mmst2  -> mmsusy + x * dst2,
    mmgl   -> mmsusy + x * dst3
    }, {x,0,0}]];

(* ******* check difference ******* *)

diff = 
 Collect[(t2lLimitS1S2MSMG - DmtOverMtSUSYUniversal (4 Pi)^4) //. {
     mmgl -> mgl^2, mgl -> MSUSY, mmu -> Q^2, mmsusy -> MSUSY^2,
     mmt -> mt^2
   }, {Xt, g3}, 
   Simplify[# //. Log[x_/y_] :> Log[x] - Log[y], MSUSY > 0 && Q > 0 && mt > 0] &];

(* diff still contains power-suppressed terms O(mt^2/MSUSY^2) *)

diff = Normal[Series[diff /. mt -> x MSUSY, {x,0,0}]];

TestEquality[diff, 0];

PrintTestSummary[];
