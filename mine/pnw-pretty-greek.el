;;; pnw-pretty-greek.el --- Pretty overlays of greek using unicode-symbols.
;;
;; Filename: pnw-pretty-greek.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: Thu Dec  6 11:22:07 2007
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 2
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
;; published by the Free Software Foundation; either version 2, or
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

;; Snippet to make “lambda” fontify as a lambda character. This is
;; LawrenceMitchell’s modification to StefanMonnier’s rewrite of
;; OliverScholz’s rewrite of LukeGorrie’s pretty-lambda.el.
(when nil
  (defun pretty-lambdas ()
    (font-lock-add-keywords
     nil `(("(\\(lambda\\>\\)"
            (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                      ,(make-char 'greek-iso8859-7 107))
                      nil))))))
  (add-hook 'emacs-lisp-mode-hook 'pretty-lambdas)
  )

;; Pretty Greek
;; This is BenignoUria modification to Pretty Lambda. Substitutes all
;; greek letter names with its character. Very nice if you use greek
;; letters as parameters in parts of your code.
(defun pretty-greek ()
  (let ((words '("alpha" "beta" "gamma" "delta" "epsilon"
                 "zeta" "eta" "theta" "iota" "kappa"
                 "lambda" "mu" "nu" "xi" "omicron"
                 "pi" "rho" "sigma_final" "sigma" "tau"
                 "upsilon" "phi" "chi" "psi" "omega")))
    (loop for word in words
          for code = 97 then (+ 1 code)
          do (let ((greek-char (make-char 'greek-iso8859-7 code)))
               (font-lock-add-keywords
                nil
                `((,(concat "\\(" "^" "\\|" "\_<" "\\)"
                            "\\(" word "\\)" "[[:alpha:]]")
                   (0 (progn
                        (decompose-region (match-beginning 2) (match-end 2))
                        nil)))))
               (font-lock-add-keywords
                nil
                `((,(concat "\\(" "^" "\\|" "\_<" "\\)"
                            "\\(" word "\\)" "[^[:alpha:]]")
                   (0 (progn (compose-region (match-beginning 2) (match-end 2)
                                             ,greek-char)
                             nil)))))))))
;; (add-hook 'lisp-mode-hook 'pretty-greek)
(add-hook 'emacs-lisp-mode-hook 'pretty-greek)
;; (add-hook 'c-mode-common-hook 'pretty-greek)

(provide 'pnw-pretty-greek)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pnw-pretty-greek.el ends here
