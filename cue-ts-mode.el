;;; cue-ts-mode.el --- Tree-sitter support for Cue  -*- lexical-binding: t; -*-

;; Homepage: https://github.com/ZharMeny/cue-ts-mode
;; Package-Requires: ((emacs "29.1"))
;; Package-Version: 0.3.0
;; SPDX-License-Identifier: BlueOak-1.0.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A major mode for editing the CUE data constraint language, powered by
;; tree-sitter.

;;; Code:

(require 'treesit)

(defcustom cue-ts-mode-indent-offset 8
  "Number of spaces for each indentation step in `cue-ts-mode'."
  :type 'integer :safe 'integerp :group 'cue)

(defvar cue-ts-mode--font-lock-feature-list
  '((comment variable-name)
    (keyword string type)
    (attribute builtin constant escape number)
    (bracket delimiter error function operator punctuation variable-use)))

(defvar cue-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :feature 'string
   :language 'cue
   '((string) @font-lock-string-face)
   :feature 'escape
   :language 'cue
   :override t
   '([(escape_byte) (escape_char) (escape_unicode)] @font-lock-escape-face)
   :feature 'keyword
   :language 'cue
   :override t
   '((for_clause ["for" "in"] @font-lock-keyword-face)
     (guard_clause "if" @font-lock-keyword-face)
     (import_declaration "import" @font-lock-keyword-face)
     (interpolation (identifier) @font-lock-keyword-face)
     (let_clause "let" @font-lock-keyword-face)
     (package_clause "package" @font-lock-keyword-face)
     (raw_interpolation
      [(identifier) @font-lock-keyword-face
       (selector_expression (identifier) @font-lock-keyword-face)]))
   :feature 'attribute
   :language 'cue
   '((attribute :anchor (identifier) @font-lock-preprocessor-face))
   :feature 'bracket
   :language 'cue
   '(["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face)
   :feature 'builtin
   :language 'cue
   '((builtin_function) @font-lock-builtin-face)
   :feature 'comment
   :language 'cue
   '((comment) @font-lock-comment-face)
   :feature 'constant
   :language 'cue
   '([(boolean) (bottom) (null) (top)] @font-lock-constant-face)
   :feature 'delimiter
   :language 'cue
   '("," @font-lock-delimiter-face
     (field ":" @font-lock-delimiter-face)
     (selector_expression "." @font-lock-delimiter-face))
   :feature 'function
   :language 'cue
   '((call_expression
      function:
      (selector_expression (identifier) @font-lock-function-call-face)))
   :feature 'number
   :language 'cue
   '([(float) (number)] @font-lock-number-face)
   :feature 'operator
   :language 'cue
   (let ((relational-operators '("!=" "<" "<=" ">" ">=" "=~" "!~")))
     `((optional "?" @font-lock-operator-face)
       (required "!" @font-lock-operator-face)
       (source_file alias: "=" @font-lock-operator-face)
       (binary_expression operator: ["&" "&&" "*" "+" "-" "/" "==" "|" "||"
                                     ,@relational-operators]
                          @font-lock-operator-face)
       (unary_expression operator: ["!" "*" "+" "-" ,@relational-operators]
                         @font-lock-operator-face)))
   :feature 'punctuation
   :language 'cue
   '((ellipsis) @font-lock-punctuation-face)
   :feature 'type
   :language 'cue
   '((primitive_type) @font-lock-type-face)
   :feature 'variable-name
   :language 'cue
   '((for_clause "for" (identifier) @font-lock-variable-name-face)
     (label (identifier) @font-lock-variable-name-face)
     (let_clause left: (identifier) @font-lock-variable-name-face)
     (optional (identifier) @font-lock-variable-name-face)
     (required (identifier) @font-lock-variable-name-face)
     (source_file alias: (identifier) @font-lock-variable-name-face "="))
   :feature 'variable-use
   :language 'cue
   '((binary_expression (identifier) @font-lock-variable-use-face)
     (for_clause "in" :anchor (identifier) @font-lock-variable-use-face)
     (let_clause right: (identifier) @font-lock-variable-use-face)
     (list_lit (identifier) @font-lock-variable-use-face)
     (selector_expression (identifier) @font-lock-variable-use-face)
     (source_file alias: "=" (identifier) @font-lock-variable-name-face)
     (unary_expression (identifier) @font-lock-variable-use-face))
   :feature 'error
   :language 'cue
   :override t
   '((ERROR) @font-lock-warning-face)))

(defvar cue-ts-mode--indent-rules
  '((cue ((parent-is "source_file") column-0 0)
         ((node-is ")") parent-bol 0)
         ((node-is "]") parent-bol 0)
         ((node-is "}") parent-bol 0)
         ((parent-is "arguments") parent-bol cue-ts-mode-indent-offset)
         ((parent-is "binary_expression") parent-bol 0)
         ((parent-is "list_lit") parent-bol cue-ts-mode-indent-offset)
         ((parent-is "string") parent-bol cue-ts-mode-indent-offset)
         ((parent-is "struct_lit") parent-bol cue-ts-mode-indent-offset)
         (no-node parent-bol 0))))

(defvar cue-ts--flymake-proc nil)

(defun cue-ts-flymake (report-fn &rest _args)
  "CUE backend for Flymake.
For what REPORT-FN means, see Info node `(flymake) Backend functions'."
  (unless (executable-find "cue")
    (error "Cannot find a suitable CUE interpreter"))
  (if (process-live-p cue-ts--flymake-proc)
      (kill-process cue-ts--flymake-proc))
  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq
       cue-ts--flymake-proc
       (make-process
        :name "cue-ts-flymake" :noquery t :connection-type 'pipe
        :buffer (generate-new-buffer " *cue-ts-flymake*")
        :command '("cue" "vet")
        :sentinel
        (lambda (proc _event)
          (when (memq (process-status proc) '(exit signal))
            (unwind-protect
                (if (with-current-buffer source (eq proc cue-ts--flymake-proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (cl-loop
                       while (search-forward-regexp
                              (rx (seq bol
                                       (group (+ not-newline))
                                       ":\n"
                                       (* not-newline)
                                       ".cue"
                                       ":"
                                       (group (+ digit))
                                       ":"
                                       (group (+ digit))
                                       eol))
                              nil t)
                       for msg = (match-string 1)
                       for (beg . end) = (flymake-diag-region
                                          source
                                          (string-to-number (match-string 2)))
                       for type = :warning
                       when (and beg end)
                       collect (flymake-make-diagnostic source beg end type msg)
                       into diags
                       finally (funcall report-fn diags)))
                  (flymake-log :warning "Canceling obsolete check %s" proc))
              (kill-buffer (process-buffer proc)))))))
      (process-send-region cue-ts--flymake-proc (point-min) (point-max))
      (process-send-eof cue-ts--flymake-proc))))

;;;###autoload
(define-derived-mode cue-ts-mode prog-mode "CUE"
  "Major mode for editing the CUE data constraint language, powered by tree-sitter."
  :group 'cue
  (unless (treesit-ready-p 'cue)
    (error "Tree-sitter for CUE isn't available"))
  (add-hook 'flymake-diagnostic-functions #'cue-ts-flymake nil t)
  (setq-local comment-end "")
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "//\\s-*")
  (setq-local treesit-font-lock-feature-list cue-ts-mode--font-lock-feature-list)
  (setq-local treesit-font-lock-settings cue-ts-mode--font-lock-settings)
  (setq-local treesit-simple-indent-rules cue-ts-mode--indent-rules)
  (treesit-parser-create 'cue)
  (treesit-major-mode-setup))

;;;###autoload
(if (treesit-ready-p 'cue t)
    (add-to-list 'auto-mode-alist '("\\.cue\\'" . cue-ts-mode)))

(provide 'cue-ts-mode)
;;; cue-ts-mode.el ends here
