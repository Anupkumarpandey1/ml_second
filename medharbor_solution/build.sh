#!/bin/bash
# Compile LaTeX to PDF (run twice for TOC and cross-references)
pdflatex -interaction=nonstopmode medharbor_case_study.tex
pdflatex -interaction=nonstopmode medharbor_case_study.tex
echo "Done — medharbor_case_study.pdf generated"
