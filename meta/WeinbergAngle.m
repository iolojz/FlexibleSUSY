
BeginPackage["WeinbergAngle`", {"SARAH`", "CConversion`", "Parameters`", "SelfEnergies`", "TextFormatting`", "ThresholdCorrections`", "TreeMasses`", "Vertices`"}];

GetBottomMass::usage="";
GetTopMass::usage="";

ExpressWeinbergAngleInTermsOfGaugeCouplings::usage="";
DeltaRhoHat2LoopSM::usage="";
DeltaRHat2LoopSM::usage="";
RhoHatTree::usage="";
InitGenerationOfDiagrams::usage="";
DeltaVBwave::usage="";
DeltaVBvertex::usage="";
DeltaVBbox::usage="";
CreateDeltaVBContributions::usage="";
CreateDeltaVBCalculation::usage="";

Begin["`Private`"];

GetBottomMass[] := ThresholdCorrections`GetParameter[TreeMasses`GetMass[TreeMasses`GetDownQuark[3,True]]];
GetTopMass[] := ThresholdCorrections`GetParameter[TreeMasses`GetMass[TreeMasses`GetUpQuark[3,True]]];

FindMassZ2[masses_List] :=
    FindMass2[masses, SARAH`VectorZ];

FindMass2[masses_List, particle_] :=
    Module[{massExpr},
           massExpr = Cases[masses, TreeMasses`FSMassMatrix[{mass_}, particle, ___] :> mass];
           If[Head[massExpr] =!= List || massExpr === {},
              Print["Error: Could not find mass of ", particle,
                    " in masses list."];
              Return[0];
             ];
           TreeMasses`ReplaceDependenciesReverse[massExpr[[1]]]
          ];

(*extracts squared tree-level mass of Z boson before mixing with additional Z`*)
UnmixedZMass2[] :=
    Module[{ZMassMatrix, extraGaugeCouplings, submatrixList, submatrix, mass2Eigenvalues},
           ZMassMatrix = SARAH`MassMatrix[SARAH`VectorZ];
           Assert[MatrixQ[ZMassMatrix]];
           extraGaugeCouplings = Cases[SARAH`Gauge, x_ /; FreeQ[x, SARAH`hypercharge] && FreeQ[x, SARAH`left] && FreeQ[x, SARAH`color] :> x[[4]]];
           submatrixList = ZMassMatrix[[#, #]] & /@ Flatten[Table[{i, j}, {i, 1, Length[ZMassMatrix]}, {j, i + 1, Length[ZMassMatrix]}], 1];
           submatrix = Cases[submatrixList, x_ /; And @@ (FreeQ[x, #] & /@ extraGaugeCouplings)];
           If[Length[submatrix] != 1, Print["Error: Photon-Z mass matrix could not be identified"]; Return[0];];
           mass2Eigenvalues = Eigenvalues[submatrix];
           If[Length[mass2Eigenvalues] != 2 || !MemberQ[mass2Eigenvalues, 0], Print["Error: Determination of UnmixedZMass2 failed"]; Return[0];];
           Select[mass2Eigenvalues, # =!= 0 &][[1]] /. Parameters`ApplyGUTNormalization[]
          ];

(*extracts squared tree-level mass of W boson before mixing with additional W`*)
UnmixedWMass2[] :=
    Module[{WMassMatrix, extraGaugeCouplings, submatrixList, submatrix, mass2Eigenvalues},
           WMassMatrix = SARAH`MassMatrix[SARAH`VectorW];
           Assert[MatrixQ[WMassMatrix]];
           extraGaugeCouplings = Cases[SARAH`Gauge, x_ /; FreeQ[x, SARAH`hypercharge] && FreeQ[x, SARAH`left] && FreeQ[x, SARAH`color] :> x[[4]]];
           submatrixList = WMassMatrix[[#, #]] & /@ Flatten[Table[{i, j}, {i, 1, Length[WMassMatrix]}, {j, i + 1, Length[WMassMatrix]}], 1];
           submatrix = Cases[submatrixList, x_ /; And @@ (FreeQ[x, #] & /@ extraGaugeCouplings)];
           If[Length[submatrix] != 1, Print["Error: W mass matrix could not be identified"]; Return[0];];
           mass2Eigenvalues = Eigenvalues[submatrix];
           If[Length[DeleteDuplicates[mass2Eigenvalues]] != 1, Print["Error: Determination of UnmixedWMass2 failed"]; Return[0];];
           mass2Eigenvalues[[1]] /. Parameters`ApplyGUTNormalization[]
          ];

(*checks whether the Gell-Mann-Nishijima relation is valid*)
GellMannNishijimaRelationHolds[] :=
    Module[{photonMassMatrix, extraGaugeCouplings, submatrixIndices, BW3pos, photonEigenSystem, photonVector},
           If[FreeQ[SARAH`Gauge, SARAH`hypercharge] || FreeQ[SARAH`Gauge, SARAH`left], Print["Error: hypercharge or left gauge group does not exist. Please choose another method for the determination of the Weinberg angle."]; Return[False];];
           photonMassMatrix = SARAH`MassMatrix[SARAH`VectorP];
           Assert[MatrixQ[photonMassMatrix]];
           If[Length[photonMassMatrix] > 4, Print["Error: neutral vector boson mass matrix is too large to be diagonalized"]; Return[False];];
           extraGaugeCouplings = Cases[SARAH`Gauge, x_ /; FreeQ[x, SARAH`hypercharge] && FreeQ[x, SARAH`left] && FreeQ[x, SARAH`color] :> x[[4]]];
           submatrixIndices = Flatten[Table[{i, j}, {i, 1, Length[photonMassMatrix]}, {j, i + 1, Length[photonMassMatrix]}], 1];
           BW3pos = Flatten[Extract[submatrixIndices, Position[photonMassMatrix[[#, #]] & /@ submatrixIndices, x_ /; And @@ (FreeQ[x, #] & /@ extraGaugeCouplings), {1}, Heads -> False]]];
           If[Length[BW3pos] != 2, Print["Error: Photon-Z mass matrix could not be identified"]; Return[False];];
           photonEigenSystem = Eigensystem[photonMassMatrix];
           photonVector = Extract[photonEigenSystem[[2]], Position[photonEigenSystem[[1]], 0]];
           If[!MemberQ[Total[Abs[Part[#, Complement[Range[Length[photonMassMatrix]], BW3pos]] & /@ photonVector], {2}], 0], Print["Error: SM-like photon could not be identified. Please choose another method for the determination of the Weinberg angle."]; Return[False];];
           True
          ];

(*calculates rho_0 from SU(2)_L representations of the Higgs multipletts as in (16) from 0801.1345 [hep-ph]*)
RhoZero[] :=
    Module[{hyperchargePos, leftPos, vevlist},
           If[!GellMannNishijimaRelationHolds[], Print["Error: the Gell-Mann-Nishijima relation does not hold. Please choose another method for the determination of the Weinberg angle."]; Return[0];];
           hyperchargePos = Position[SARAH`Gauge, x_ /; !FreeQ[x, SARAH`hypercharge], {1}][[1, 1]];
           leftPos = Position[SARAH`Gauge, x_ /; !FreeQ[x, SARAH`left], {1}][[1, 1]];
           vevlist = SARAH`DEFINITION[SARAH`EWSB][SARAH`VEVs];
           (* extract isospin from SU(2)_left representation and its third component from Gell-Mann-Nishijima formula with given hypercharge and electric charge = 0 *)
           vevlist = vevlist /. {fieldname_Symbol, vevinfo_List, comp1_List, __} :> Flatten[{vevinfo Boole[ReleaseHold[SARAH`getElectricCharge[comp1[[1]]]] == 0], (SA`DimensionGG[fieldname, leftPos] - 1) / 2, -SA`ChargeGG[fieldname, hyperchargePos]}];
           If[!FreeQ[vevlist, None], Print["Error: determination of electric charge did not work"]; Return[0];];
           Simplify[Plus @@ ((#[[3]]^2 - #[[4]]^2 + #[[3]]) Abs[#[[1]] #[[2]] Sqrt[2]]^2 & /@ vevlist) / Plus @@ (2 #[[4]]^2 Abs[#[[1]] #[[2]] Sqrt[2]]^2 & /@ vevlist),
                    Element[Alternatives @@ Cases[SARAH`DEFINITION[SARAH`EWSB][SARAH`VEVs][[All, 2, 1]], x_ /; Parameters`IsRealParameter[x]], Reals]]
          ];

ExpressWeinbergAngleInTermsOfGaugeCouplings[] :=
    Module[{solution},
           Print["Expressing Weinberg angle in terms of model parameters ..."];
           solution = ArcCos[Sqrt[UnmixedWMass2[] / UnmixedZMass2[] / RhoZero[]]];
           Simplify[solution]
          ];

extPars={SINTHETAW, RHOHATRATIO, GFERMI, MW, MZ, MT, RHO2, DELTARHAT1LOOP, PIZZTMZ};
Do[Format[extPars[[i]],CForm]=Format[ToString[extPars[[i]]],OutputForm],{i,Length[extPars]}];

(*returns coefficients of 1 and gamma5 in Higgs-top-top vertices*)
HiggsTopVertices[higgsName_] :=
    Module[{indexRange, indexList, topQuark, higgsVertices},
           If[FreeQ[TreeMasses`GetParticles[], higgsName] || TreeMasses`GetDimensionWithoutGoldstones[higgsName] == 0, Return[{}];];
           indexRange = TreeMasses`GetParticleIndices[higgsName][[All, 2]];
           If[indexRange === {}, indexRange = {1};];
           indexList = Flatten[Table @@ {Table[ToExpression["i" <> ToString[k]], {k, Length[indexRange]}], Sequence @@ Table[{ToExpression["i" <> ToString[k]], 1, indexRange[[k]]}, {k, Length[indexRange]}]}, Length[indexRange] - 1];
           topQuark = Level[TreeMasses`GetUpQuark[{3}], {Boole[ListQ[TreeMasses`GetUpQuark[{3}]]]}][[1]];
           higgsVertices = Vertices`StripGroupStructure[SARAH`Vertex[{bar[topQuark], topQuark, higgsName[#]}] & /@ indexList, SARAH`ctNr /@ Range[4]];
           higgsVertices = Cases[higgsVertices, {{__, higgsField_}, {coeffPL_, SARAH`PL}, {coeffPR_, SARAH`PR}} /; !TreeMasses`IsGoldstone[higgsField] :> {higgsField /. List -> Sequence, Simplify[(coeffPR + coeffPL)/2], Simplify[(coeffPR - coeffPL)/2]}];
           higgsVertices
          ];

(*generalize Higgs dependent part of (C.5) and (C.6) in hep-ph/9606211 analogous to (C.9) and (C.10)*)
HiggsContributions2LoopSM[] :=
    Module[{higgsVEVlist, higgsDep},
           If[!ValueQ[SARAH`VEVSM], Print["Error: SM like Higgs vev does not exist."]; Return[0];];
           higgsVEVlist = Cases[Parameters`GetDependenceSPhenoRules[], RuleDelayed[SARAH`VEVSM, repr_] :> repr];
           If[higgsVEVlist === {}, higgsVEVlist = {SARAH`VEVSM};];
           higgsDep = (Abs[#[[2]]]^2 - Abs[#[[3]]]^2) RHO2[FlexibleSUSY`M[#[[1]]]/MT] &;
           Simplify[3 (GFERMI MT higgsVEVlist[[1]] / (8 Pi^2 Sqrt[2]))^2 (Plus @@ (higgsDep /@ Join[HiggsTopVertices[SARAH`HiggsBoson], HiggsTopVertices[SARAH`PseudoScalar]]))]
          ];

(*formula according to (C.6) from hep-ph/9606211*)
DeltaRhoHat2LoopSM[]:=
    Module[{gY, alphaDRbar, expr, result},
           gY = SARAH`hyperchargeCoupling FlexibleSUSY`GUTNormalization[SARAH`hyperchargeCoupling];
           alphaDRbar = gY^2 SARAH`leftCoupling^2 / (4 Pi (gY^2 + SARAH`leftCoupling^2));
           expr = (alphaDRbar SARAH`strongCoupling^2/(16 Pi^3 SINTHETAW^2)(-2.145 MT^2/MW^2 + 1.262 Log[MT/MZ] - 2.24 - 0.85 MZ^2/MT^2) + HiggsContributions2LoopSM[]) / (1 + PIZZTMZ / MZ^2);
           result = Parameters`CreateLocalConstRefs[expr] <> "\n";
           result = result <> TreeMasses`ExpressionToString[expr, "deltaRhoHat2LoopSM"];
           result
          ];

(*formula according to (C.5) from hep-ph/9606211*)
DeltaRHat2LoopSM[]:=
    Module[{gY, alphaDRbar, expr, result},
           gY = SARAH`hyperchargeCoupling FlexibleSUSY`GUTNormalization[SARAH`hyperchargeCoupling];
           alphaDRbar = gY^2 SARAH`leftCoupling^2 / (4 Pi (gY^2 + SARAH`leftCoupling^2));
           expr = alphaDRbar SARAH`strongCoupling^2/(16 Pi^3 SINTHETAW^2 (1 - SINTHETAW^2))(2.145 MT^2/MZ^2 + 0.575 Log[MT/MZ] - 0.224 - 0.144 MZ^2/MT^2) - HiggsContributions2LoopSM[] (1 - DELTARHAT1LOOP) RHOHATRATIO;
           result = Parameters`CreateLocalConstRefs[expr] <> "\n";
           result = result <> TreeMasses`ExpressionToString[expr, "deltaRHat2LoopSM"];
           result
          ];

(*calculates tree-level value of rhohat parameter from umixed and mixed Z mass as well as RhoZero*)
RhoHatTree[]:=
    Module[{Zmass2unmixed, Zmass2mixed, expr, result},
           Zmass2unmixed = UnmixedZMass2[];
           Zmass2mixed = FindMassZ2[TreeMasses`GetUnmixedParticleMasses[] /. Parameters`ApplyGUTNormalization[]];
           expr = Simplify[RhoZero[] Zmass2unmixed / Zmass2mixed /. SARAH`Weinberg -> ExpressWeinbergAngleInTermsOfGaugeCouplings[], SARAH`hyperchargeCoupling > 0 && SARAH`leftCoupling > 0];
           result = Parameters`CreateLocalConstRefs[expr] <> "\n";
           result = result <> "rhohat_tree = ";
           result = result <> CConversion`RValueToCFormString[expr] <> ";";
           result
          ];


(*functions for creation of wave-function renormalization, vertex and box corrections:*)

InitGenerationOfDiagrams[eigenstates_:FlexibleSUSY`FSEigenstates] :=
    Module[{},
           SA`CurrentStates = eigenstates;
           SARAH`InitVertexCalculation[eigenstates, False];
           SARAH`ReadVertexList[eigenstates, False, False, True];
           SARAH`MakeCouplingLists;
          ];

ExcludeDiagrams[diagrs_List, excludeif_:(False &)] := Select[diagrs, !Or @@ (excludeif /@ (Cases[#, Rule[Internal[_], x_] :> x, Infinity])) &];

GenerateDiagramsWave[particle_] :=
    Module[{couplings, insertrules, diagrs},
           couplings = {C[SARAH`External[1], SARAH`Internal[1], SARAH`AntiField[SARAH`Internal[2]]]};
           insertrules = {SARAH`External[1] -> particle, SARAH`Internal[1] -> SARAH`FieldToInsert[1], SARAH`Internal[2] -> SARAH`FieldToInsert[2]};
           diagrs = SARAH`InsFields[{couplings /. insertrules, insertrules}];
           (*add indices for later summation*)
           diagrs = diagrs /. (Rule[SARAH`Internal[i_], x_] /; TreeMasses`GetDimension[x] > 1) :> Rule[SARAH`Internal[i], x[{ToExpression["SARAH`gI" <> ToString[i]]}]];
           diagrs = diagrs /. (Rule[SARAH`External[i_], x_] /; TreeMasses`GetDimension[x] > 1) :> Rule[SARAH`External[i], x[{ToExpression["SARAH`gO" <> ToString[i]]}]];
           diagrs = ({couplings /. #[[2]], #[[2]]}) & /@ diagrs;
           diagrs
          ];

WaveResult[diagr_List, includeGoldstones_] :=
    Module[{coupl, intparticles, intfermion, intscalar, result, intpartwithindex},
           coupl = (diagr[[1, 1]] /. C[a__] -> SARAH`Cp[a])[SARAH`PL];
           intparticles = ({SARAH`Internal[1], SARAH`Internal[2]} /. diagr[[2]]) /. {SARAH`bar[p_] :> p, Susyno`LieGroups`conj[p_] :> p};
           intfermion = Select[intparticles, TreeMasses`IsFermion][[1]];
           intscalar = Select[intparticles, TreeMasses`IsScalar][[1]];
           result = -coupl Susyno`LieGroups`conj[coupl] SARAH`B1[0, SARAH`Mass2[intfermion], SARAH`Mass2[intscalar]];
           intpartwithindex = Reverse[Cases[intparticles, _[{_}]]];
           Do[result = SARAH`sum[intpartwithindex[[i, 1, 1]], If[includeGoldstones, 1, TreeMasses`GetDimensionStartSkippingGoldstones[intpartwithindex[[i]]]], TreeMasses`GetDimension[intpartwithindex[[i]]], result],
                 {i, Length[intpartwithindex]}];
           result
          ];

CompleteWaveResult[particle_, includeGoldstones_] := Plus @@ (WaveResult[#, includeGoldstones] &) /@ ExcludeDiagrams[GenerateDiagramsWave[particle], If[includeGoldstones, TreeMasses`IsVector, TreeMasses`IsVector[#] || TreeMasses`IsGoldstone[#] &]];

DeltaVBwave[includeGoldstones_:False] :=
    Module[{neutrinofields, neutrinoresult, chargedleptonfields, chargedleptonresult},
           (*TODO: insert tests for consistency of TreeMasses`GetDimension[] and Length[TreeMasses`GetSM...Leptons[]]*)
           neutrinofields = TreeMasses`GetSMNeutralLeptons[];
           If[Length[neutrinofields] == 1,
              neutrinoresult = {WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {SARAH`gO1}, neutrinofields[[1]]}, CompleteWaveResult[neutrinofields[[1]], includeGoldstones]]},
              If[Length[neutrinofields] != 3, Print["Error: DeltaVBwave does not work because there are neither 1 nor 3 neutrino fields"]; Return[{}];];
              neutrinoresult = {WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {}, neutrinofields[[1]]}, CompleteWaveResult[neutrinofields[[1]], includeGoldstones]],
                                WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {}, neutrinofields[[2]]}, CompleteWaveResult[neutrinofields[[2]], includeGoldstones]]};];
           chargedleptonfields = TreeMasses`GetSMChargedLeptons[];
           If[Length[chargedleptonfields] == 1,
              chargedleptonresult = {WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {SARAH`gO1}, chargedleptonfields[[1]]}, CompleteWaveResult[chargedleptonfields[[1]], includeGoldstones]]},
              If[Length[chargedleptonfields] != 3, Print["Error: DeltaVBwave does not work because there are neither 1 nor 3 charged lepton fields"]; Return[{}];];
              chargedleptonresult = {WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {}, chargedleptonfields[[1]]}, CompleteWaveResult[chargedleptonfields[[1]], includeGoldstones]],
                                     WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {}, chargedleptonfields[[2]]}, CompleteWaveResult[chargedleptonfields[[2]], includeGoldstones]]};];
           Join[neutrinoresult, chargedleptonresult]
          ];

GenerateDiagramsVertex[part1_, part2_, part3_] :=
    Module[{couplings, insertrules, diagrs},
           couplings = {C[SARAH`External[1], SARAH`AntiField[SARAH`Internal[2]], SARAH`Internal[3]],
                        C[SARAH`External[2], SARAH`Internal[1], SARAH`AntiField[SARAH`Internal[3]]],
                        C[SARAH`External[3], SARAH`AntiField[SARAH`Internal[1]], SARAH`Internal[2]]};
           insertrules = {SARAH`External[1] -> part1, SARAH`External[2] -> part2, SARAH`External[3] -> part3,
                          SARAH`Internal[1] -> SARAH`FieldToInsert[1], SARAH`Internal[2] -> SARAH`FieldToInsert[2], SARAH`Internal[3] -> SARAH`FieldToInsert[3]};
           diagrs = SARAH`InsFields[{couplings /. insertrules, insertrules}];
           (*add indices for later summation*)
           diagrs = diagrs /. (Rule[SARAH`Internal[i_], x_] /; TreeMasses`GetDimension[x] > 1) :> Rule[SARAH`Internal[i], x[{ToExpression["SARAH`gI" <> ToString[i]]}]];
           diagrs = diagrs /. (Rule[SARAH`External[i_], x_] /; TreeMasses`GetDimension[x] > 1) :> Rule[SARAH`External[i], x[{ToExpression["SARAH`gO" <> ToString[i]]}]];
           (*TODO: test for more than 1 field in SARAH`VectorW*)
           diagrs = ({couplings /. #[[2]], #[[2]]}) & /@ diagrs;
           diagrs
          ];

(*True for Majorana fermions and outgoing Dirac fermions*)
IsOutgoingFermion[particle_] := TreeMasses`IsFermion[particle] && (!FreeQ[particle, SARAH`bar] || SARAH`AntiField[particle] === particle);

(*True for Majorana Fermions and incoming Dirac fermions*)
IsIncomingFermion[particle_] := TreeMasses`IsFermion[particle] && FreeQ[particle, SARAH`bar];

VertexResultFSS[diagr_List, includeGoldstones_] :=
    Module[{extparticles, extvectorindex, extoutindex, extinindex, couplSSV, couplFFSout, couplFFSin, intparticles, intfermion, intscalars, result, intpartwithindex},
           extparticles = {SARAH`External[1], SARAH`External[2], SARAH`External[3]} /. diagr[[2]];
           extvectorindex = Position[extparticles, x_ /; TreeMasses`IsVector[x], {1}, Heads -> False][[1, 1]];
           extoutindex = Position[extparticles, x_ /; IsOutgoingFermion[x], {1}, Heads -> False][[1, 1]];
           extinindex = Complement[{1, 2, 3}, {extvectorindex, extoutindex}][[1]];
           (*TODO: ensure correct momentum direction at SSV vertex*)
           couplSSV = -diagr[[1, extvectorindex]] /. C[a__] -> SARAH`Cp[a];
           couplFFSout = (diagr[[1, extoutindex]] /. C[a__] -> SARAH`Cp[a])[SARAH`PR];
           couplFFSin = (diagr[[1, extinindex]] /. C[a__] -> SARAH`Cp[a])[SARAH`PL];
           intparticles = ({SARAH`Internal[1], SARAH`Internal[2], SARAH`Internal[3]} /. diagr[[2]]) /. {SARAH`bar[p_] :> p, Susyno`LieGroups`conj[p_] :> p};
           intfermion = Select[intparticles, TreeMasses`IsFermion][[1]];
           intscalars = Select[intparticles, TreeMasses`IsScalar];
           result = 1/2 couplSSV couplFFSout couplFFSin (1/2 + SARAH`B0[0, SARAH`Mass2[intscalars[[1]]], SARAH`Mass2[intscalars[[2]]]]
                                                         + SARAH`Mass2[intfermion] SARAH`C0[SARAH`Mass2[intfermion], SARAH`Mass2[intscalars[[1]]], SARAH`Mass2[intscalars[[2]]]]);
           intpartwithindex = Reverse[Cases[intparticles, _[{_}]]];
           Do[result = SARAH`sum[intpartwithindex[[i, 1, 1]], If[includeGoldstones, 1, TreeMasses`GetDimensionStartSkippingGoldstones[intpartwithindex[[i]]]], TreeMasses`GetDimension[intpartwithindex[[i]]], result],
                 {i, Length[intpartwithindex]}];
           result
          ];

VertexResultFFS[diagr_List, includeGoldstones_] :=
    Module[{extparticles, extvectorindex, extoutindex, extinindex, fermiondirectok1, fermiondirectok2, needfermionflip, innaturalorder, orderedparticles, couplFFVPL, couplFFVPR, couplFFSout, couplFFSin, intparticles, intfermions, intscalar, result, intpartwithindex},
           extparticles = {SARAH`External[1], SARAH`External[2], SARAH`External[3]} /. diagr[[2]];
           extvectorindex = Position[extparticles, x_ /; TreeMasses`IsVector[x], {1}, Heads -> False][[1, 1]];
           extoutindex = Position[extparticles, x_ /; IsOutgoingFermion[x], {1}, Heads -> False][[1, 1]];
           extinindex = Complement[{1, 2, 3}, {extvectorindex, extoutindex}][[1]];
           (*is fermion flip necessary?*)
           fermiondirectok1 = Or @@ IsIncomingFermion /@ Complement[List @@ diagr[[1, extoutindex]], {SARAH`External[extoutindex]} /. diagr[[2]]];
           fermiondirectok2 = Or @@ IsOutgoingFermion /@ Complement[List @@ diagr[[1, extinindex]], {SARAH`External[extinindex]} /. diagr[[2]]];
           needfermionflip = !(fermiondirectok1 && fermiondirectok2);
           (*are fermions in natural order (outgoing before incoming)?*)
           innaturalorder = (IsOutgoingFermion[#[[1]]] && IsIncomingFermion[#[[2]]]) & @ Select[List @@ diagr[[1, extvectorindex]], TreeMasses`IsFermion];
           orderedparticles = If[innaturalorder, List @@ diagr[[1, extvectorindex]], Reverse[List @@ diagr[[1, extvectorindex]]]];
           (*use non-flipped or flipped FFV vertex appropriately*)
           couplFFVPL = (SARAH`Cp @@ If[needfermionflip, Reverse[orderedparticles], orderedparticles])[SARAH`PL];
           couplFFVPR = (SARAH`Cp @@ If[needfermionflip, Reverse[orderedparticles], orderedparticles])[SARAH`PR];
           couplFFSout = (diagr[[1, extoutindex]] /. C[a__] -> SARAH`Cp[a])[SARAH`PR];
           couplFFSin = (diagr[[1, extinindex]] /. C[a__] -> SARAH`Cp[a])[SARAH`PL];
           intparticles = ({SARAH`Internal[1], SARAH`Internal[2], SARAH`Internal[3]} /. diagr[[2]]) /. {SARAH`bar[p_] :> p, Susyno`LieGroups`conj[p_] :> p};
           intfermions = Select[intparticles, TreeMasses`IsFermion];
           intscalar = Select[intparticles, TreeMasses`IsScalar][[1]];
           result = couplFFSout couplFFSin (-couplFFVPL FlexibleSUSY`M[intfermions[[1]]] FlexibleSUSY`M[intfermions[[2]]] SARAH`C0[SARAH`Mass2[intscalar], SARAH`Mass2[intfermions[[1]]], SARAH`Mass2[intfermions[[2]]]]
                                            + 1/2 couplFFVPR (-1/2 + SARAH`B0[0, SARAH`Mass2[intfermions[[1]]], SARAH`Mass2[intfermions[[2]]]]
                                                              + SARAH`Mass2[intscalar] SARAH`C0[SARAH`Mass2[intscalar], SARAH`Mass2[intfermions[[1]]], SARAH`Mass2[intfermions[[2]]]]));
           intpartwithindex = Reverse[Cases[intparticles, _[{_}]]];
           Do[result = SARAH`sum[intpartwithindex[[i, 1, 1]], If[includeGoldstones, 1, TreeMasses`GetDimensionStartSkippingGoldstones[intpartwithindex[[i]]]], TreeMasses`GetDimension[intpartwithindex[[i]]], result],
                 {i, Length[intpartwithindex]}];
           result
          ];

VertexResult[diagr_List, includeGoldstones_] :=
    Module[{intparticles, nFermions, nScalars},
           intparticles = {SARAH`Internal[1], SARAH`Internal[2], SARAH`Internal[3]} /. diagr[[2]];
           nFermions = Count[TreeMasses`IsFermion /@ intparticles, True];
           nScalars = Count[TreeMasses`IsScalar /@ intparticles, True];
           Switch[{nFermions, nScalars},
                  {1, 2}, VertexResultFSS[diagr, includeGoldstones],
                  {2, 1}, VertexResultFFS[diagr, includeGoldstones],
                  _, Print["Error: diagram type not supported"]; 0]
          ];

VertexTreeResult[part1_, part2_] :=
    Module[{part1withindex, part2withindex},
           If[TreeMasses`GetDimension[part1] > 1, part1withindex = part1[{SARAH`gO1}], part1withindex = part1];
           If[TreeMasses`GetDimension[part2] > 1, part2withindex = part2[{SARAH`gO2}], part2withindex = part2];
           SARAH`Cp[part2withindex, part1withindex, Susyno`LieGroups`conj[SARAH`VectorW]][SARAH`PL]
          ];

CompleteVertexResult[part1_, part2_, includeGoldstones_] := (Plus @@ (VertexResult[#, includeGoldstones] &) /@ ExcludeDiagrams[GenerateDiagramsVertex[part1, part2, Susyno`LieGroups`conj[SARAH`VectorW]], If[includeGoldstones, TreeMasses`IsVector, TreeMasses`IsVector[#] || TreeMasses`IsGoldstone[#] &]]) / VertexTreeResult[part1, part2];

DeltaVBvertex[includeGoldstones_:False] :=
    Module[{neutrinofields, chargedleptonfields, result},
           (*TODO: insert tests for consistency of TreeMasses`GetDimension[] and Length[TreeMasses`GetSM...Leptons[]]*)
           neutrinofields = TreeMasses`GetSMNeutralLeptons[];
           chargedleptonfields = TreeMasses`GetSMChargedLeptons[];
           If[Length[neutrinofields] != Length[chargedleptonfields], Print["Error: DeltaVBvertex does not work because the numbers of neutrino and charged lepton fields are different"]; Return[{}];];
           If[Length[neutrinofields] == 1,
              result = {WeinbergAngle`DeltaVB[{WeinbergAngle`fsvertex, {SARAH`gO1, SARAH`gO2}},
                                              CompleteVertexResult[chargedleptonfields[[1]], SARAH`bar[neutrinofields[[1]]], includeGoldstones]]},
              If[Length[neutrinofields] != 3, Print["Error: DeltaVBvertex does not work because there are neither 1 nor 3 neutrino fields"]; Return[{}];];
              result = {WeinbergAngle`DeltaVB[{WeinbergAngle`fsvertex, {}, chargedleptonfields[[1]], neutrinofields[[1]]},
                                              CompleteVertexResult[chargedleptonfields[[1]], SARAH`bar[neutrinofields[[1]]], includeGoldstones]],
                        WeinbergAngle`DeltaVB[{WeinbergAngle`fsvertex, {}, chargedleptonfields[[2]], neutrinofields[[2]]},
                                              CompleteVertexResult[chargedleptonfields[[2]], SARAH`bar[neutrinofields[[2]]], includeGoldstones]]}];
           result
          ];

GenerateDiagramsBox[part1_, part2_, part3_, part4_] :=
    Module[{couplings1, couplings2, couplings3, insertrules, diagrs1, diagrs2, diagrs3},
           couplings1 = {C[SARAH`External[1], SARAH`Internal[4], SARAH`AntiField[SARAH`Internal[1]]],
                         C[SARAH`External[2], SARAH`Internal[1], SARAH`AntiField[SARAH`Internal[2]]],
                         C[SARAH`External[3], SARAH`Internal[2], SARAH`AntiField[SARAH`Internal[3]]],
                         C[SARAH`External[4], SARAH`Internal[3], SARAH`AntiField[SARAH`Internal[4]]]};
           couplings2 = {C[SARAH`External[1], SARAH`Internal[4], SARAH`AntiField[SARAH`Internal[1]]],
                         C[SARAH`External[2], SARAH`Internal[1], SARAH`AntiField[SARAH`Internal[2]]],
                         C[SARAH`External[3], SARAH`Internal[3], SARAH`AntiField[SARAH`Internal[4]]],
                         C[SARAH`External[4], SARAH`Internal[2], SARAH`AntiField[SARAH`Internal[3]]]};
           couplings3 = {C[SARAH`External[1], SARAH`Internal[4], SARAH`AntiField[SARAH`Internal[1]]],
                         C[SARAH`External[2], SARAH`Internal[2], SARAH`AntiField[SARAH`Internal[3]]],
                         C[SARAH`External[3], SARAH`Internal[1], SARAH`AntiField[SARAH`Internal[2]]],
                         C[SARAH`External[4], SARAH`Internal[3], SARAH`AntiField[SARAH`Internal[4]]]};
           insertrules = {SARAH`External[1] -> part1, SARAH`External[2] -> part2, SARAH`External[3] -> part3, SARAH`External[4] -> part4,
                          SARAH`Internal[1] -> SARAH`FieldToInsert[1], SARAH`Internal[2] -> SARAH`FieldToInsert[2], SARAH`Internal[3] -> SARAH`FieldToInsert[3], SARAH`Internal[4] -> SARAH`FieldToInsert[4]};
           diagrs1 = SARAH`InsFields[{couplings1 /. insertrules, insertrules}];
           diagrs2 = SARAH`InsFields[{couplings2 /. insertrules, insertrules}];
           diagrs3 = SARAH`InsFields[{couplings3 /. insertrules, insertrules}];
           (*add indices for later summation*)
           {diagrs1, diagrs2, diagrs3} = {diagrs1, diagrs2, diagrs3} /. (Rule[SARAH`Internal[i_], x_] /; TreeMasses`GetDimension[x] > 1) :> Rule[SARAH`Internal[i], x[{ToExpression["SARAH`gI" <> ToString[i]]}]];
           {diagrs1, diagrs2, diagrs3} = {diagrs1, diagrs2, diagrs3} /. (Rule[SARAH`External[i_], x_] /; TreeMasses`GetDimension[x] > 1) :> Rule[SARAH`External[i], x[{ToExpression["SARAH`gO" <> ToString[i]]}]];
           diagrs1 = ({couplings1 /. #[[2]], Append[#[[2]], WeinbergAngle`topoNr -> 1]}) & /@ diagrs1;
           diagrs2 = ({couplings2 /. #[[2]], Append[#[[2]], WeinbergAngle`topoNr -> 2]}) & /@ diagrs2;
           diagrs3 = ({couplings3 /. #[[2]], Append[#[[2]], WeinbergAngle`topoNr -> 3]}) & /@ diagrs3;
           Join[diagrs1, diagrs2, diagrs3]
          ];

BoxResult[diagr_List, includeGoldstones_] :=
    Module[{couplMu, couplMuNeutr, couplElNeutr, couplEl, intparticles, intfermions, toponr, result, intpartwithindex},
           couplMu = (diagr[[1, 1]] /. C[a__] -> SARAH`Cp[a])[SARAH`PL];
           couplMuNeutr = (diagr[[1, 2]] /. C[a__] -> SARAH`Cp[a])[SARAH`PR];
           couplElNeutr = (diagr[[1, 3]] /. C[a__] -> SARAH`Cp[a])[SARAH`PL];
           couplEl = (diagr[[1, 4]] /. C[a__] -> SARAH`Cp[a])[SARAH`PR];
           intparticles = ({SARAH`Internal[1], SARAH`Internal[2], SARAH`Internal[3], SARAH`Internal[4]} /. diagr[[2]]) /. {SARAH`bar[p_] :> p, Susyno`LieGroups`conj[p_] :> p};
           intfermions = Select[intparticles, TreeMasses`IsFermion];
           toponr = WeinbergAngle`topoNr /. diagr[[2]];
           result = couplMu couplMuNeutr couplElNeutr couplEl;
           If[toponr == 1,
              result = result * SARAH`D27[Sequence @@ SARAH`Mass2 /@ intparticles]];
           If[toponr == 2 && TreeMasses`IsFermion[intparticles[[1]]],
              result = result * (-1) * SARAH`D27[Sequence @@ SARAH`Mass2 /@ intparticles]];
           If[toponr == 2 && TreeMasses`IsScalar[intparticles[[1]]],
              result = result * 1/2 * FlexibleSUSY`M[intfermions[[1]]] FlexibleSUSY`M[intfermions[[2]]] SARAH`D0[Sequence @@ SARAH`Mass2 /@ intparticles]];
           If[toponr == 3 && TreeMasses`IsFermion[intparticles[[1]]],
              result = result * 1/2 * FlexibleSUSY`M[intfermions[[1]]] FlexibleSUSY`M[intfermions[[2]]] SARAH`D0[Sequence @@ SARAH`Mass2 /@ intparticles]];
           If[toponr == 3 && TreeMasses`IsScalar[intparticles[[1]]],
              result = result * (-1) * SARAH`D27[Sequence @@ SARAH`Mass2 /@ intparticles]];
           intpartwithindex = Reverse[Cases[intparticles, _[{_}]]];
           Do[result = SARAH`sum[intpartwithindex[[i, 1, 1]], If[includeGoldstones, 1, TreeMasses`GetDimensionStartSkippingGoldstones[intpartwithindex[[i]]]], TreeMasses`GetDimension[intpartwithindex[[i]]], result],
                 {i, Length[intpartwithindex]}];
           result
          ];

CompleteBoxResult[part1_, part2_, part3_, part4_, includeGoldstones_] := Plus @@ (BoxResult[#, includeGoldstones] &) /@ ExcludeDiagrams[GenerateDiagramsBox[part1, part2, part3, part4], If[includeGoldstones, TreeMasses`IsVector, TreeMasses`IsVector[#] || TreeMasses`IsGoldstone[#] &]];

DeltaVBbox[includeGoldstones_:False] :=
    Module[{neutrinofields, chargedleptonfields, result},
           neutrinofields = TreeMasses`GetSMNeutralLeptons[];
           chargedleptonfields = TreeMasses`GetSMChargedLeptons[];
           If[Length[neutrinofields] != Length[chargedleptonfields], Print["Error: DeltaVBbox does not work because the numbers of neutrino and charged lepton fields are different"]; Return[{}];];
           If[Length[neutrinofields] == 1,
              result = {WeinbergAngle`DeltaVB[{WeinbergAngle`fsbox, {SARAH`gO1, SARAH`gO2, SARAH`gO3, SARAH`gO4}},
                                              CompleteBoxResult[chargedleptonfields[[1]], SARAH`bar[neutrinofields[[1]]], neutrinofields[[1]], SARAH`bar[chargedleptonfields[[1]]], includeGoldstones]]},
              If[Length[neutrinofields] != 3, Print["Error: DeltaVBbox does not work because there are neither 1 nor 3 neutrino fields"]; Return[{}];];
              result = {WeinbergAngle`DeltaVB[{WeinbergAngle`fsbox, {}},
                                              CompleteBoxResult[chargedleptonfields[[2]], SARAH`bar[neutrinofields[[2]]], neutrinofields[[1]], SARAH`bar[chargedleptonfields[[1]]], includeGoldstones]]}];
           result
          ];

indextype = CConversion`CreateCType[CConversion`ScalarType[CConversion`integerScalarCType]];

AddIndices[{}] := "";

AddIndices[{ind_}] := indextype <> " " <> CConversion`ToValidCSymbolString[ind];

AddIndices[{ind1_, ind2_}] := indextype <> " " <> CConversion`ToValidCSymbolString[ind1] <> ", " <> indextype <> " " <> CConversion`ToValidCSymbolString[ind2];

AddIndices[{ind1_, ind2_, ind3_, ind4_}] := indextype <> " " <> CConversion`ToValidCSymbolString[ind1] <> ", " <> indextype <> " " <> CConversion`ToValidCSymbolString[ind2] <>
                                    ", " <> indextype <> " " <> CConversion`ToValidCSymbolString[ind3] <> ", " <> indextype <> " " <> CConversion`ToValidCSymbolString[ind4];

CreateContributionName[WeinbergAngle`DeltaVB[{type_, {___}}, _]] := "delta_vb_" <> StringReplace[CConversion`ToValidCSymbolString[type], StartOfString ~~ "fs" ~~ rest_ :> rest];

CreateContributionName[WeinbergAngle`DeltaVB[{type_, {___}, spec_}, _]] := "delta_vb_" <> StringReplace[CConversion`ToValidCSymbolString[type], StartOfString ~~ "fs" ~~ rest_ :> rest] <> "_" <> CConversion`ToValidCSymbolString[spec];

CreateContributionName[WeinbergAngle`DeltaVB[{type_, {___}, spec1_, spec2_}, _]] := "delta_vb_" <> StringReplace[CConversion`ToValidCSymbolString[type], StartOfString ~~ "fs" ~~ rest_ :> rest] <> "_" <> CConversion`ToValidCSymbolString[spec1] <> "_" <> CConversion`ToValidCSymbolString[spec2];

CreateContributionPrototype[deltaVBcontri_WeinbergAngle`DeltaVB] := CreateContributionName[deltaVBcontri] <> "(" <> AddIndices[deltaVBcontri[[1, 2]]] <> ") const";

(*based on CreateNPointFunction from SelfEnergies.m*)
CreateDeltaVBContribution[deltaVBcontri_WeinbergAngle`DeltaVB, vertexRules_List] :=
    Module[{expr, functionName, type, prototype, decl, body},
           expr = deltaVBcontri[[2]];
           functionName = CreateContributionPrototype[deltaVBcontri];
           type = CConversion`CreateCType[CConversion`ScalarType[CConversion`complexScalarCType]];
           prototype = type <> " " <> functionName <> ";\n";
           decl = "\n" <> type <> " CLASSNAME::" <> functionName <> "\n{\n";
           body = Parameters`CreateLocalConstRefs[expr] <> "\n";
           body = body <> type <> " result;\n\n";
           body = body <> CConversion`ExpandSums[Parameters`DecreaseIndexLiterals[Parameters`DecreaseSumIndices[expr], TreeMasses`GetParticles[]] /.
                                                 vertexRules /.
                                                 a_[List[i__]] :> a[i], "result"];
           body = body <> "\nreturn result;";
           body = TextFormatting`IndentText[TextFormatting`WrapLines[body]];
           decl = decl <> body <> "}\n";
           {prototype, decl}
          ];

PrintDeltaVBContributionName[WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {}, part_}, _]] :=
    "deltaVB wave-function contribution for field " <> CConversion`ToValidCSymbolString[part];

PrintDeltaVBContributionName[WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, {idx_}, part_}, _]] :=
    "deltaVB wave-function contribution for field " <> CConversion`ToValidCSymbolString[part] <> "[" <> CConversion`ToValidCSymbolString[idx] <> "]";

PrintDeltaVBContributionName[WeinbergAngle`DeltaVB[{WeinbergAngle`fsvertex, {}, part1_, part2_}, _]] :=
    "deltaVB vertex contribution for fields " <> CConversion`ToValidCSymbolString[part1] <> ", " <> CConversion`ToValidCSymbolString[part2];

PrintDeltaVBContributionName[WeinbergAngle`DeltaVB[{WeinbergAngle`fsvertex, {__}}, _]] := "deltaVB vertex contribution";

PrintDeltaVBContributionName[WeinbergAngle`DeltaVB[{WeinbergAngle`fsbox, {___}}, _]] := "deltaVB box contribution";

(*based on CreateNPointFunctions from SelfEnergies.m*)
CreateDeltaVBContributions[deltaVBcontris_List, vertexRules_List] :=
    Module[{relevantVertexRules, prototypes = "", defs = "", vertexFunctionNames = {}, p, d},
           Print["Converting vertex functions ..."];
           relevantVertexRules = Cases[vertexRules, r:(Rule[a_, b_] /; !FreeQ[deltaVBcontris, a])];
           {prototypes, defs, vertexFunctionNames} = SelfEnergies`CreateVertexExpressions[relevantVertexRules, False];
           Print["Generating C++ code for ..."];
           For[k = 1, k <= Length[deltaVBcontris], k++,
               Print["   ", PrintDeltaVBContributionName[deltaVBcontris[[k]]]];
               {p, d} = CreateDeltaVBContribution[deltaVBcontris[[k]], vertexFunctionNames];
               prototypes = prototypes <> p;
               defs = defs <> d;
              ];
           {prototypes, defs}
          ];

CreateContributionCall[deltaVBcontri_ /; MatchQ[deltaVBcontri, WeinbergAngle`DeltaVB[{_, {}, ___}, _]]] := CreateContributionName[deltaVBcontri] <> "()";

CreateContributionCall[deltaVBcontri_ /; MatchQ[deltaVBcontri, WeinbergAngle`DeltaVB[{_, {SARAH`gO1}, ___}, _]]] := CreateContributionName[deltaVBcontri] <> "(0) + " <> CreateContributionName[deltaVBcontri] <> "(1)";

CreateContributionCall[deltaVBcontri_ /; MatchQ[deltaVBcontri, WeinbergAngle`DeltaVB[{_, {SARAH`gO1, SARAH`gO2}, ___}, _]]] := CreateContributionName[deltaVBcontri] <> "(0, 0) + " <> CreateContributionName[deltaVBcontri] <> "(1, 1)";

CreateContributionCall[deltaVBcontri_ /; MatchQ[deltaVBcontri, WeinbergAngle`DeltaVB[{_, {SARAH`gO1, SARAH`gO2, SARAH`gO3, SARAH`gO4}, ___}, _]]] := CreateContributionName[deltaVBcontri] <> "(1, 1, 0, 0)";

CreateDeltaVBCalculation[deltaVBcontris_List] :=
    Module[{type, result = "", boxcontri, vertexcontris, wavecontris},
           If[!(TreeMasses`FindMixingMatrixSymbolFor[TreeMasses`GetSMNeutralLeptons[][[1]]] === Null), Print["Warning: neutrino mixing is not considered in muon decay"];];
           type = CConversion`CreateCType[CConversion`ScalarType[CConversion`complexScalarCType]];
           boxcontri = Cases[deltaVBcontris, WeinbergAngle`DeltaVB[{WeinbergAngle`fsbox, __}, _]][[1]];
           vertexcontris = Cases[deltaVBcontris, WeinbergAngle`DeltaVB[{WeinbergAngle`fsvertex, __}, _]];
           wavecontris = Cases[deltaVBcontris, WeinbergAngle`DeltaVB[{WeinbergAngle`fswave, __}, _]];
           result = result <> "const " <> type <> " a1 = ";
           result = result <> CreateContributionCall[boxcontri] <> ";\n";
           result = result <> "const " <> type <> " deltaV =\n   ";
           For[k = 1, k <= Length[vertexcontris], k++,
               If[k > 1, result = result <> " + ";];
               result = result <> CreateContributionCall[vertexcontris[[k]]];
              ];
           result = result <> ";\n";
           result = result <> "const " <> type <> " deltaZ =\n   ";
           For[k = 1, k <= Length[wavecontris], k++,
               If[k > 1, result = result <> " + ";];
               result = result <> CreateContributionCall[wavecontris[[k]]];
              ];
           result <> ";"
          ];

End[];

EndPackage[];
