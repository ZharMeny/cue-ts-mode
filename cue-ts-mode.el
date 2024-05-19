;;; cue-ts-mode.el --- Tree-sitter support for Cue  -*- lexical-binding: t; -*-

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A major mode for editing Cue Data Constraint Language files, powered
;; by tree-sitter.

;;; Code:

(require 'treesit)

(defcustom cue-ts-mode-indent-offset 8
  "Number of spaces for each indentation step in `cue-ts-mode'."
  :version "0.1.0"
  :type 'integer
  :safe 'integerp
  :group 'cue)

(defvar cue-ts-mode--operators
  '("!" "!=" "!~" "&" "&&" "*" "+" "-" "..." "/" ":"
    "<" "<=" "=" "==" "=~" ">" ">=" "?" "|" "||")
  "Cue operators for tree-sitter font-locking.")

(defvar cue-ts-mode--indent-rules
  '((cue
     ((parent-is "source_file") column-0 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((node-is "}") parent-bol 0)
     ((parent-is "struct_lit") parent-bol cue-ts-mode-indent-offset)
     (no-node parent-bol 0))))

(defvar cue-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :feature 'bracket
   :language 'cue
   '((["(" ")" "{" "}" "[" "]"]) @font-lock-bracket-face)

   :feature 'comment
   :language 'cue
   '((comment) @font-lock-comment-face)

   :feature 'constant
   :language 'cue
   '(([(boolean) (bottom) (null) (top)]) @font-lock-constant-face)

   :feature 'delimiter
   :language 'cue
   '((["," "."]) @font-lock-delimiter-face)

   :feature 'error
   :language 'cue
   '((ERROR) @font-lock-warning-face)

   :feature 'keyword
   :language 'cue
   ;; If we use `import_declaration' here, the module name will also
   ;; be higlighted, which we don't want.
   '((["import" (identifier)]) @font-lock-keyword-face)

   :feature 'number
   :language 'cue
   '(([(float) (number)]) @font-lock-number-face)

   :feature 'operator
   :language 'cue
   `(([,@cue-ts-mode--operators]) @font-lock-operator-face)

   :feature 'string
   :language 'cue
   '((string) @font-lock-string-face)

   :feature 'type
   :language 'cue
   '((primitive_type) @font-lock-type-face)))

;;;###autoload
(define-derived-mode cue-ts-mode prog-mode "Cue"
  "Major mode for editing Cue Language files, powered by tree-sitter."
  (when (treesit-ready-p 'cue)
    (treesit-parser-create 'cue)
    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local treesit-font-lock-settings cue-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
		'((comment)
		  (keyword string)
		  (constant number type)
		  (bracket delimiter error operator)))
    (setq-local treesit-simple-indent-rules cue-ts-mode--indent-rules)


    (treesit-major-mode-setup)))

;;;###autoload
(if (treesit-ready-p 'cue)
    (add-to-list 'auto-mode-alist '("\\.cue\\'" . cue-ts-mode)))

(provide 'cue-ts-mode)
;;; cue-ts-mode.el ends here
