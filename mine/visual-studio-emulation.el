;;; visual-studio-emulation.el --- Visual Studio like Keybindings
;;
;; Filename: visual-studio-emulation.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: fre jun 12 09:16:26 2009 (+0200)
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
;;   Required feature `visual-studio-emulation' was not provided.
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

;; Joakim Bergman wanted these bindings to emulate Visual Studio Keybindings
;; to avoid having to use the "Alt Gr" key.
(progn
  (global-set-key [(control meta \2)] (lambda () (interactive) (insert "@")))
  (global-set-key [(control meta \3)] (lambda () (interactive) (insert "ÂÃ£")))
  (global-set-key [(control meta \4)] (lambda () (interactive) (insert "$")))
  (global-set-key [(control meta \7)] (lambda () (interactive) (insert "{")))
  (global-set-key [(control meta \8)] (lambda () (interactive) (insert "[")))
  (global-set-key [(control meta \9)] (lambda () (interactive) (insert "]")))
  (global-set-key [(control meta \0)] (lambda () (interactive) (insert "}")))
  (global-set-key [(control meta \+)] (lambda () (interactive) (insert "\\")))
  )

(provide 'visual-studio-emulation)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; visual-studio-emulation.el ends here
