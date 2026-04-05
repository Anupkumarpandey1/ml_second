@echo off
REM Compile LaTeX to PDF on Windows (requires MiKTeX or TeX Live)
pdflatex -interaction=nonstopmode medharbor_case_study.tex
pdflatex -interaction=nonstopmode medharbor_case_study.tex
echo Done — medharbor_case_study.pdf generated
pause
