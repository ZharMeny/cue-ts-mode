.POSIX:

EMACS=emacs

.PHONY: all
all: cue-ts-mode.elc

.PHONY: clean
clean:
	rm -f *.elc

.SUFFIXES: .el .elc
.el.elc:
	$(EMACS) -Q --batch -L . -f batch-byte-compile $<
