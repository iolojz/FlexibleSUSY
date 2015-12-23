DIR          := meta
MODNAME      := meta

META_SRC     := \
		$(DIR)/AnomalousDimension.m \
		$(DIR)/BetaFunction.m \
		$(DIR)/CConversion.m \
		$(DIR)/Constraint.m \
		$(DIR)/ConvergenceTester.m \
		$(DIR)/FlexibleSUSY.m \
		$(DIR)/LatticeUtils.m \
		$(DIR)/LoopMasses.m \
		$(DIR)/Observables.m \
		$(DIR)/Parameters.m \
		$(DIR)/Phases.m \
		$(DIR)/SelfEnergies.m \
		$(DIR)/EWSB.m \
		$(DIR)/TestSuite.m \
		$(DIR)/TextFormatting.m \
		$(DIR)/ThreeLoopMSSM.m \
		$(DIR)/ThreeLoopSM.m \
		$(DIR)/ThresholdCorrections.m \
		$(DIR)/Traces.m \
		$(DIR)/TreeMasses.m \
		$(DIR)/TwoLoop.m \
		$(DIR)/Utils.m \
		$(DIR)/Vertices.m \
		$(DIR)/WriteOut.m \
		$(DIR)/WeinbergAngle.m \
		$(DIR)/GMuonMinus2.m

.PHONY:         all-$(MODNAME) clean-$(MODNAME) distclean-$(MODNAME)

all-$(MODNAME):

clean-$(MODNAME):

distclean-$(MODNAME): clean-$(MODNAME)

clean::         clean-$(MODNAME)

distclean::     distclean-$(MODNAME)
