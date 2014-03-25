;;; pgo-man.el --- Setup Man Integration.
;;
;; Filename: pgo-man.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: fre jun 12 09:48:19 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 7
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   Required feature `pgo-man' was not provided.
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

;; Man and WoMan
;; See: http://www.emacswiki.org/cgi-bin/wiki/ManMode

;; man-completion.el --- completion for M-x man
;; See: http://www.geocities.com/user42_kevin/man-completion/index.html
(eval-after-load "man" '(require 'man-completion nil t))

(when (require 'woman nil t)
  ;; Read manual pages using man program.
  (global-set-key [(control c) (M)] 'woman)

  ;; Do NOT open in own frame.
  (setq woman-use-own-frame nil)
  )

;;; iman.el --- call man & Info viewers with completion
(when (require 'iman nil t)
  )

;;; man-preview.el --- preview nroff man file source
(when (require 'man-preview nil t)
  )

(provide 'pgo-man)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-man.el ends here
