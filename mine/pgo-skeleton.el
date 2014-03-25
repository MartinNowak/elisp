;;; pgo-skeleton.el --- Setup skeleton.el (Lisp language extension for writing statement skeletons)
;;
;; Filename: pgo-skeleton.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: fre jun 12 08:51:24 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 4
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   Required feature `pgo-skeleton' was not provided.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(when (require 'skeleton nil t)

  ;; Another simple optimization - you'll almost always type parens,
  ;; braces and square brackets pairwise so why not let Emacs do this
  ;; for you?

  ;; ToDo: Needs some tuning to become useful for me.
  (when nil                 ;not useful in all cases so I skip for now
    (defun skeleton-cc-mode-hook ()
      (setq skeleton-pair t)
      (define-key c-mode-map "(" 'skeleton-pair-insert-maybe)
      (define-key c-mode-map "{" 'skeleton-pair-insert-maybe)
      (define-key c-mode-map "[" 'skeleton-pair-insert-maybe)
      (define-key c-mode-map "\"" 'skeleton-pair-insert-maybe)
      (define-key c-mode-map "'" 'skeleton-pair-insert-maybe))
    (add-hook 'c-mode-hook 'skeleton-cc-mode-hook)
    )

  ;; Emacs is really great editor. A bit clumsy for beginners, but
  ;; powerful when you get used to it. I have just added skeleton-pair
  ;; insert stuff to my .emacs file. This enables direct insert of
  ;; additional character, say ), when I type (. Nice! Here is the elisp
  ;; code for it - I found it at emacsWiki site

  ;; enable skeleton-pair insert globally
  (when nil
    (setq skeleton-pair t)
    (setq skeleton-pair-on-word t) ; apply skeleton trick even in front of a word.
    (global-set-key (kbd "(")  'skeleton-pair-insert-maybe)
    (global-set-key (kbd "[")  'skeleton-pair-insert-maybe)
    (global-set-key (kbd "{")  'skeleton-pair-insert-maybe)
    (global-set-key (kbd "\"") 'skeleton-pair-insert-maybe)
    (global-set-key (kbd "\'") 'skeleton-pair-insert-maybe)
    )

  (define-skeleton pnw/latex-skeleton
    "Inserts a Latex letter skeleton into current buffer.
    This only makes sense for empty buffers."
    "EmpfÂÃ¤nger: "
    "\\documentclass[a4paper]{letter}\n"
    "\\usepackage{german}\n"
    "\\usepackage[latin1]{inputenc}\n"
    "\\name{A. SchrÂÃ¶der}\n"
    "\\address{Alexander SchrÂÃ¶der \\\\ Langstrasse 104 \\\\ 8004 ZÂÃ¼rich}\n"
    "\\begin{document}\n"
    "\\begin{letter}{" str | " *** EmpfÂÃ¤nger *** " "}\n"
    "\\opening{" _ "}\n\n"
    "\\closing{Mit freundlichen GrÂÃ¼ssen,}\n"
    "\\end{letter}\n"
    "\\end{document}\n"
    )
  )

(provide 'pgo-skeleton)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-skeleton.el ends here
