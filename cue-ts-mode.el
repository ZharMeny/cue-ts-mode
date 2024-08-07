;;; cue-ts-mode.el --- Tree-sitter support for Cue  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 ZharMeny

;; This file is not part of GNU Emacs.

;; Homepage: https://github.com/ZharMeny/cue-ts-mode
;; Package-Requires: ((emacs "29.1"))
;; Package-Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing Cue Data Constraint Language files, powered
;; by tree-sitter.

;;; Code:

(require 'treesit)

(defcustom cue-ts-mode-indent-offset 8
  "Number of spaces for each indentation step in `cue-ts-mode'."
  :type 'integer :safe 'integerp :group 'cue)

(defvar cue-ts-mode--brackets
  '("(" ")" "[" "]" "{" "}")
  "Cue brackets for tree-sitter font-locking.")

(defvar cue-ts-mode--operators
  '("!" "!=" "!~" "&" "&&" "*" "+" "-" "..." "/" ":"
    "<" "<=" "=" "==" "=~" ">" ">=" "?" "|" "||")
  "Cue operators for tree-sitter font-locking.")

(defvar cue-ts-mode--indent-rules
  '((cue ((parent-is "source_file") column-0 0)
         ((node-is ")") parent-bol 0)
         ((node-is "]") parent-bol 0)
         ((node-is "}") parent-bol 0)
         ((parent-is "arguments") parent-bol cue-ts-mode-indent-offset)
         ((parent-is "list_lit") parent-bol cue-ts-mode-indent-offset)
         ((parent-is "string") parent-bol cue-ts-mode-indent-offset)
         ((parent-is "struct_lit") parent-bol cue-ts-mode-indent-offset)
         (no-node parent-bol 0))))

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
   `([,@cue-ts-mode--brackets] @font-lock-bracket-face)
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
   '(["," "."] @font-lock-delimiter-face)
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
   `([,@cue-ts-mode--operators] @font-lock-operator-face)
   :feature 'type
   :language 'cue
   '((primitive_type) @font-lock-type-face)
   :feature 'variable-name
   :language 'cue
   '((for_clause "for" :anchor (identifier) @font-lock-variable-name-face)
     (label [(identifier) @font-lock-variable-name-face
             (optional (identifier) @font-lock-variable-name-face)
             (required (identifier) @font-lock-variable-name-face)])
     (let_clause left: (identifier) @font-lock-variable-name-face)
     (source_file alias:
                  (identifier) @font-lock-variable-name-face
                  "="
                  (identifier)))
   :feature 'variable-use
   :language 'cue
   '((binary_expression (identifier) @font-lock-variable-use-face)
     (for_clause "in" :anchor (identifier) @font-lock-variable-use-face)
     (list_lit (identifier) @font-lock-variable-use-face)
     (unary_expression (identifier) @font-lock-variable-use-face)
     (selector_expression (identifier) @font-lock-variable-use-face)
     (source_file alias:
                  (identifier)
                  "="
                  (identifier) @font-lock-variable-name-face))
   :feature 'error
   :language 'cue
   :override t
   '((ERROR) @font-lock-warning-face)))

;;;###autoload
(define-derived-mode cue-ts-mode prog-mode "Cue"
  "Major mode for editing Cue Language files, powered by tree-sitter."
  :group 'cue
  (when (treesit-ready-p 'cue)
    (treesit-parser-create 'cue)
    (setq-local comment-end ""
                comment-start "// "
                comment-start-skip "//\\s-*"
                treesit-font-lock-feature-list
                '((comment)
                  (keyword string type)
                  (attribute builtin constant escape number variable-name)
                  (bracket delimiter error function operator variable-use))
                treesit-font-lock-settings cue-ts-mode--font-lock-settings
                treesit-simple-indent-rules cue-ts-mode--indent-rules))
  (treesit-major-mode-setup))

;;;###autoload
(if (treesit-ready-p 'cue t)
    (add-to-list 'auto-mode-alist '("\\.cue\\'" . cue-ts-mode)))

(provide 'cue-ts-mode)
;;; cue-ts-mode.el ends here
