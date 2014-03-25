;;; pgo-autoconf.el --- Setup AutoConf.
;;
;; Filename: pgo-autoconf.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 11 15:58:01 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 8
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `autoconf-mode'.
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

(when (require 'autoconf-mode nil t)          ;GNU Emacs Standard
  (add-to-list 'auto-mode-alist
               '("/configure\\.\\(ac\\|in\\)\\'" . autoconf-mode))
  (add-to-list 'auto-mode-alist
               '("/aclocal/.*\\.m[4c]\\'" . autoconf-mode))
  (add-to-list 'auto-mode-alist
               '("/usr/share/autoconf-archive/.*\\.m[4c]\\'" . autoconf-mode))
  (add-to-list 'auto-mode-alist
               '("/m4/.*\\.m[4c]\\'" . autoconf-mode)) ;Note: Overrides m4-mode
  (add-to-list 'auto-mode-alist
               '("aclocal\\.m[4c]\\'" . autoconf-mode)
               )

  (when t
    (modify-syntax-entry ?\" "\""  autoconf-mode-syntax-table)
    ;;(modify-syntax-entry ?\' "\""  autoconf-mode-syntax-table)
    (modify-syntax-entry ?#  "<\n" autoconf-mode-syntax-table)
    (modify-syntax-entry ?\n ">#"  autoconf-mode-syntax-table)
    (modify-syntax-entry ?\( "()"   autoconf-mode-syntax-table)
    (modify-syntax-entry ?\) ")("   autoconf-mode-syntax-table)
    (modify-syntax-entry ?\[ "(]"  autoconf-mode-syntax-table)
    (modify-syntax-entry ?\] ")["  autoconf-mode-syntax-table)
    (modify-syntax-entry ?*  "."   autoconf-mode-syntax-table)
    (modify-syntax-entry ?_  "_"   autoconf-mode-syntax-table)
    )

  ;; sh-autoconf.el --- autoconf flavour for sh-mode
  ;; configure.in, acinclude.m4, etc.  This is good if you've got a lot of
  ;; shell in your configure (and like sh-mode for shell editing).
  (when nil
    (eval-after-load "sh-script"
      '(require 'sh-autoconf))
    (add-to-list 'auto-mode-alist
                 '("/configure\\.\\(ac\\|in\\)\\'" . sh-mode))
    (add-to-list 'auto-mode-alist
                 '("/ac\\(include\\|local\\)\\.m4\\'" . sh-mode))

    (require 'sh-script nil t)
    )
  )

(provide 'pgo-autoconf)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-autoconf.el ends here
