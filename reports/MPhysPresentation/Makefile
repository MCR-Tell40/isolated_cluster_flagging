# $Id: Makefile 87305 2016-02-08 13:50:32Z lafferty $
# ===============================================================================
# Purpose: simple Makefile to streamline processing latex document (just say "make" to execute)
# Author: Tomasz Skwarnicki
# Created on: 2010-09-24
# A few changes by Patrick Koppenburg on 2015-06-26
# More changes by Dónal Murray on 2017-05-23
# ===============================================================================

# name of the main latex file (do not include .tex)
MAIN = pres

# name of the target - change that to something descriptive, like paper-v0, Bs2PhiPhi-ANA-v1, etc...
TARGET = MPhysPresentation

# name of command to perform Latex (either pdflatex or latex)
LATEX = pdflatex

FIGEXT = .pdf
MAINEXT= .pdf
BUILDCOMMAND=$(LATEX) $(MAIN) && $(LATEX) $(MAIN) && $(LATEX) $(MAIN)

# list of all source files
TEXSOURCES = $(wildcard *.tex)
FIGSOURCES = $(wildcard figs/*$(FIGEXT))
SOURCES    = $(TEXSOURCES) $(FIGSOURCES)

# define output (could be making .ps instead)
OUTPUT = $(TARGET)$(MAINEXT)

# cp temporary main.pdf to target.
$(OUTPUT): $(MAIN)$(MAINEXT)
	cp $(MAIN)$(MAINEXT) $(OUTPUT)
	evince $(OUTPUT) &

# prescription how to make output (your favorite commands to process latex)
# run latex three times to make sure that all cross-references are updated
$(MAIN)$(MAINEXT): $(SOURCES) Makefile
	$(BUILDCOMMAND)

# just so we can say "make all" without knowing the output name
all: $(OUTPUT)

# remove temporary files (good idea to say "make clean" before putting things back into repository)
.PHONY : clean
clean:
	rm -f *~ *.aux *.log *.bbl *.blg *.dvi *.tmp *.out *.blg *.bbl $(OUTPUT) $(MAIN)$(MAINEXT) $(MAIN).ps $(MAIN)-prl.ps $(MAIN)-prlNotes.bib

# remove output file
rmout:
	rm $(OUTPUT) $(MAIN)$(MAINEXT)
