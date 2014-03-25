;;; pgo-scroll.el --- Setup Scrolling Behaviour (mainly for Mouse Wheel).
;;
;; Filename: pgo-scroll.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 11 19:55:38 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 9
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `custom', `mwheel', `pc-select', `scrl-margs', `timer',
;;   `widget'.
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

;; Mouse Wheel Scrolling
(when (require 'pc-select nil t)
  (global-set-key [mouse-4] 'scroll-down-nomark)
  (global-set-key [mouse-5] 'scroll-up-nomark)
  (global-set-key [mouse-6] 'scroll-down-nomark)
  (global-set-key [mouse-7] 'scroll-up-nomark)
  )
(when (require 'mwheel nil t)
  (mouse-wheel-mode t)
  (global-set-key [(mouse-4)] (lambda () (interactive) (scroll-down 3)))
  (global-set-key [(mouse-5)] (lambda () (interactive) (scroll-up 3)))
  (global-set-key [(mouse-6)] (lambda () (interactive) (scroll-down 3)))
  (global-set-key [(mouse-7)] (lambda () (interactive) (scroll-up 3)))
  (global-set-key [(wheel-down)] (lambda () (interactive) (scroll-down 3)))
  (global-set-key [(wheel-up)] (lambda () (interactive) (scroll-up 3)))
  (setq mouse-wheel-scroll-amount
        '(3                        ;default is to scroll 3 lines
          ((shift) . 1)            ;when shift is held scroll 1 line
          ((control))))            ;when control is held scroll faster
  ;; mouse-wheel-up-event - Variable: Event used for scrolling up.
  )

;; scrl-margs.el --- scroll margins minor mode
;; See: http://www.emacswiki.org/cgi-bin/wiki/ScrollMargs
(when (require 'scrl-margs nil t)
  ;;	  (autoload 'scroll-margs-mode "scrl-margs" nil t)
  ;;	  (autoload 'set-scroll-margs "scrl-margs" nil t)
  )

(provide 'pgo-scroll)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-scroll.el ends here
