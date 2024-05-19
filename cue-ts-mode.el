;;; cue-ts-mode.el --- Tree-sitter support for Cue  -*- lexical-binding: t; -*-

;; Package-Requires: ((emacs "29.1"))

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

(defvar cue-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :feature 'comment
   :language 'cue
   '((comment) @font-lock-comment-face)

   :feature 'keyword
   :language 'cue
   '((identifier) @font-lock-keyword-face)

   :feature 'string
   :language 'cue
   '((string) @font-lock-string-face)

   :feature 'type
   :language 'cue
   '((primitive_type) @font-lock-type-face)

   :feature 'error
   :language 'cue
   '((ERROR) @font-lock-warning-face)))

;;;###autoload
(define-derived-mode cue-ts-mode prog-mode "Cue"

  (when (treesit-ready-p 'cue)
    (treesit-parser-create 'cue)
    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local treesit-font-lock-settings cue-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
		'((comment)
		  (keyword string)
		  (type)
		  (error)))

    (treesit-major-mode-setup)))

;;;###autoload
(if (treesit-ready-p 'cue)
    (add-to-list 'auto-mode-alist '("\\.cue\\'" . cue-ts-mode)))

(provide 'cue-ts-mode)
;;; cue-ts-mode.el ends here
