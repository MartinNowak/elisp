;;; org-mumamo.el --- MuMaMo in org-mode.
;;
;; Filename: org-mumamo.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor okt 29 21:22:53 2009 (+0100)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 18
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `backquote', `bytecomp', `mumamo'.
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

;; Here is some code for using other major modes inside of org-mode.
;; It uses blocks like the org-mode "#+BEGIN_SOURCE", "#+END_SOURCE"
;; blocks.  This is sort of fun to play with but not necessarily
;; stable.  Thanks to Lennart for showing me how the MuMaMo code
;; works.  Requires MuMaMo-mode
;; See: http://www.emacswiki.org/cgi-bin/wiki/MuMaMo
;;
;; Example:
;;
;; #+BEGIN_ruby-mode
;; # ruby-mode active in the block
;; def eric
;; # nothing else
;; end
;; #+END_ruby-mode
;;
;; #+BEGIN_emacs-lisp-mode
;; (defun this-is-lisp ()
;;   )
;; #+END_emacs-lisp-mode

(require 'mumamo)

(defvar mumamo-org-modes
  '(ruby-mode emacs-lisp-mode c-mode)
  "Modes to include in org-files")

(defvar mumamo-org-chunk-functions
  nil
  "The automatically defined mumamo-chunk-org-* functions for use
cramming other modes into org-mode.  See `mumamo-org-modes'
`mumamo-quick-static-chunk'.")

(setq mumamo-org-chunk-functions
      (mapcar                               ;for
       (lambda (mode)                       ;each mode given
         (let* ((m-str (symbol-name mode))
                (m-name (substring m-str 0 (- (length m-str) 5))))
           (eval `(defun ,(intern (format "mumamo-chunk-org-%S" mode)) (pos min max) ;define org mode mumamo
                    ,(format "%s support inside org BEGIN END blocks" mode)
                    (mumamo-quick-static-chunk
                     pos min max
                     (format "#+BEGIN_SRC %s" ,m-name)
                     (format "#+END_SRC %s" ,m-name)
                     t (quote ,mode) nil)))))
       mumamo-org-modes))

(eval `(define-mumamo-multi-major-mode org-mumamo
         ,(format "Turn on multiple major modes with main major mode
org-mode.\n\n%s"
                  (mapconcat (lambda (el) (format "- %S" el))
                             mumamo-org-modes "\n"))
         ("Org Source Blocks Family" org-mode ,mumamo-org-chunk-functions)))

(provide 'org-mumamo)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-mumamo.el ends here
