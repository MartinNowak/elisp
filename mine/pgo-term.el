;;; pgo-term.el --- Setup Serial Port Terminal Support
;;
;; Filename: pgo-term.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: fre jun 12 08:49:25 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 6
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   None
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

;; Debian/Ubuntu: sudo apt-get install ckermit gkermit
(defun term-kermit-serial-port ()
  "Run the terminal emulator kermit from within Emacs.
Escape character: Ctrl-\ (ASCII 28, FS): enabled
Type the escape character followed by C to quit."
  (interactive)
  (set-buffer (make-term "terminal" "kermit"
                         (concat (getenv "HOME") "/" "term-PPCBug.kermit")))
  (term-mode)
  (term-char-mode)
  (setq term-prompt-regexp "PPC6-Bug>")
  (make-local-variable 'font-lock-defaults)

  (when (require 'ppcbug nil t)
    (setq font-lock-defaults '(ppcbug-font-lock-keywords nil nil))
    )
  (font-lock-mode t)
  (switch-to-buffer "*terminal*" t))

(defalias 'kermit-serial 'term-kermit-serial-port)

(provide 'pgo-term)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-term.el ends here
