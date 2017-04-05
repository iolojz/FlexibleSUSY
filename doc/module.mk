DIR          := doc
MODNAME      := doc

DOC_MK       := \
		$(DIR)/module.mk

DOC_TMPL     := \
		$(DIR)/mainpage.dox.in \
		$(DIR)/addons.dox \
		$(DIR)/building.dox \
		$(DIR)/documentation.dox \
		$(DIR)/FlexibleEFTHiggs.dox \
		$(DIR)/hssusy.dox \
		$(DIR)/install.dox \
		$(DIR)/librarylink.dox \
		$(DIR)/meta_code.dox \
		$(DIR)/model_file.dox \
		$(DIR)/package.dox \
		$(DIR)/slha_input.dox \
		$(DIR)/utilities.dox

DOC_INSTALL_DIR := $(INSTALL_DIR)/$(DIR)

HTML_OUTPUT_DIR := $(DIR)/html
MAN_OUTPUT_DIR  := $(DIR)/man
PDF_OUTPUT_DIR  := $(DIR)
IMAGE_DIR       := $(DIR)/images
IMAGES          := $(IMAGE_DIR)/Mh_Xt.png
INDEX_PAGE      := $(HTML_OUTPUT_DIR)/index.html
MAN_PAGE        := $(MAN_OUTPUT_DIR)/index.html
DOXYFILE        := $(DIR)/Doxyfile
DOXYGEN_MAINPAGE:= $(DIR)/mainpage.dox

PAPER_PDF       := $(PDF_OUTPUT_DIR)/flexiblesusy-paper.pdf
PAPER_SRC       := $(DIR)/flexiblesusy-paper.tex
PAPER_STY       := $(DIR)/tikz-uml.sty

LATEX_TMP       := \
		$(patsubst %.pdf, %.aux, $(PAPER_PDF)) \
		$(patsubst %.pdf, %.log, $(PAPER_PDF)) \
		$(patsubst %.pdf, %.toc, $(PAPER_PDF)) \
		$(patsubst %.pdf, %.out, $(PAPER_PDF)) \
		$(patsubst %.pdf, %.spl, $(PAPER_PDF))

.PHONY:         all-$(MODNAME) clean-$(MODNAME) distclean-$(MODNAME) \
		$(INDEX_PAGE) $(MAN_PAGE) doc doc-html doc-man doc-pdf \
		release-paper

doc: all-$(MODNAME)

doc-pdf: $(PAPER_PDF)

doc-html: $(INDEX_PAGE)

doc-man: $(MAN_PAGE)

all-$(MODNAME): doc-html doc-man doc-pdf
		@true

ifneq ($(INSTALL_DIR),)
install-src::
		install -d $(DOC_INSTALL_DIR)
		install -m u=rw,g=r,o=r $(DOC_TMPL) $(DOC_INSTALL_DIR)
		install -m u=rw,g=r,o=r $(DOC_MK) $(DOC_INSTALL_DIR)
		install -m u=rw,g=r,o=r $(DOXYFILE) $(DOC_INSTALL_DIR)
		install -m u=rw,g=r,o=r $(PAPER_SRC) $(DOC_INSTALL_DIR)
		install -m u=rw,g=r,o=r $(PAPER_STY) $(DOC_INSTALL_DIR)
		install -d $(INSTALL_DIR)/$(IMAGE_DIR)
		install -m u=rw,g=r,o=r $(IMAGES) $(INSTALL_DIR)/$(IMAGE_DIR)
endif

clean-$(MODNAME):
		-rm -f $(LATEX_TMP)

distclean-$(MODNAME): clean-$(MODNAME)
		-rm -rf $(HTML_OUTPUT_DIR)
		-rm -f $(DOXYGEN_MAINPAGE)
		-rm -f $(PAPER_PDF)

clean::         clean-$(MODNAME)

distclean::     distclean-$(MODNAME)

$(INDEX_PAGE):
		( cat $(DOXYFILE) ; \
		  echo "INPUT = $(MODULES) $(README_FILE)" ; \
		  echo "OUTPUT_DIRECTORY = $(HTML_OUTPUT_DIR)" ; \
		  echo "EXCLUDE = $(ALLDEP) $(META_SRC) $(TEMPLATES) \
		        $(TEST_SRC) $(TEST_META)"; \
		  echo "EXCLUDE_PATTERNS = */test/*"; \
		  echo "IMAGE_PATH = $(IMAGE_DIR)"; \
		) | doxygen -

$(MAN_PAGE):
		( cat $(DOXYFILE) ; \
		  echo "INPUT = $(MODULES) $(README_FILE)" ; \
		  echo "OUTPUT_DIRECTORY = $(MAN_OUTPUT_DIR)" ; \
		  echo "EXCLUDE = $(ALLDEP) $(META_SRC) $(TEMPLATES) \
		        $(TEST_SRC) $(TEST_META)"; \
		  echo "EXCLUDE_PATTERNS = */test/*"; \
		  echo "GENERATE_MAN = YES"; \
		  echo "GENERATE_HTML = NO"; \
		) | doxygen -

$(PAPER_PDF): $(PAPER_SRC) $(PAPER_STY)
		pdflatex -output-directory $(PDF_OUTPUT_DIR) $<
		pdflatex -output-directory $(PDF_OUTPUT_DIR) $<

release-paper: $(PAPER_SRC) $(PAPER_STY)
		git archive --worktree-attributes --prefix=$(PKGNAME)-paper/ \
			--output=$(PKGNAME)-paper.tar.gz HEAD:doc $(notdir $^)
