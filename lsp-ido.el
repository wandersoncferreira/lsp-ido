;;; lsp-ido.el --- LSP ido integration             -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Wanderson Ferreira

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Authors: Wanderson Ferreira

;; Keywords: languages, debug
;; URL: https://github.com/wandersoncferreira/lsp-ido
;; Package-Requires: ((emacs "25.1") (lsp-mode "6.2.1"))
;; Version: 0.4
;;

;;; Commentary:

;; This package provides an interactive ido interface to the workspace symbol
;; functionality offered by lsp-mode.  For an alternative implementation based on
;; ivy, see https://github.com/emacs-lsp/lsp-ivy

;;; Code:

(require 'ido)

(require 'lsp-protocol)
(require 'lsp-mode)

(defgroup lsp-ido nil
  "LSP support for ido-based symbol completion"
  :group 'lsp-mode)

(eval-when-compile
  (lsp-interface
   (lsp-ido:FormattedSymbolInformation
    (:kind :name :location :textualRepresentation)
    (:containerName :deprecated))))

(lsp-defun lsp-ido--transform-candidate
  ((symbol-information &as &SymbolInformation)
   lsp-ido--results)
  (let* ((textual-representation
	  (lsp-render-symbol-information symbol-information ".")))
    (puthash textual-representation symbol-information lsp-ido--results)))

(lsp-defun lsp-ido--jump-selected-candidate
  ((&SymbolInformation
    :location (&Location :uri :range (&Range :start (&Position :line :character)))))
  "Jump to selected candidate."
  (find-file (lsp--uri-to-path uri))
  (goto-char (point-min))
  (forward-line line)
  (forward-char character))

(defun lsp-ido--workspace-symbol (workspaces)
  "Search against WORKSPACES with PROMPT and INITIAL-INPUT."
  (let* ((lsp-ido--results (make-hash-table :test 'equal))
	 (raw-choices
	  (with-lsp-workspaces workspaces
	    (lsp-request
	     "workspace/symbol"
	     (lsp-make-workspace-symbol-params :query "")))))
    (mapc (lambda (it)
	    (lsp-ido--transform-candidate it lsp-ido--results))
	  raw-choices)
    lsp-ido--results))


(defun lsp-ido-workspace-symbol ()
  "`ido' for lsp workspace/symbol."
  (interactive)
  (let* ((hash-table-candidates (lsp-ido--workspace-symbol (lsp-workspaces)))
	 (choice (ido-completing-read
		  "Workspace"
		  (hash-table-keys hash-table-candidates))))
    (lsp-ido--jump-selected-candidate (gethash choice hash-table-candidates))))

(provide 'lsp-ido)
;;; lsp-ido.el ends here
