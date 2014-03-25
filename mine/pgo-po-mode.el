;;; pgo-po-mode.el --- Setup po-mode.el
;;
;; Filename: pgo-po-mode.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 25 10:01:53 2009 (+0200)
;; Version:
;; Last-Updated: fre dec 18 21:16:38 2009 (+0100)
;;     Update #: 11
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `backquote', `bytecomp', `custom', `gb-po-mode', `po-compat',
;;   `po-mode', `po-mode+', `widget'.
;;
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

;; ===========================================================================
;; po-mode.el -- major mode for GNU gettext PO files
;; See: http://www.emacswiki.org/emacs-en/PoMode

(when (and (require 'po-compat nil t)
           (require 'po-mode nil t))
  (autoload 'po-mode "po-mode"
    "Major mode for translators to edit PO files" t)
  (add-to-list 'auto-mode-alist '("\\.po\\'\\|\\.po\\." . po-mode))

  ;; To use the right coding system automatically under Emacs 20 or newer,
  ;; also add:

  (autoload 'po-find-file-coding-system "po-compat")
  (modify-coding-system-alist 'file "\\.po\\'\\|\\.po\\."
                              'po-find-file-coding-system)

  ;; po-mode+.el --- Extensions to GNU gettext's `po-mode.el'.
  (when (require 'po-mode+ nil t)
    )

  ;; It is a good idea to have all lines in PO files not exceed 80
  ;; characters limit. Calling fill-paragraph while editing a message
  ;; string makes every line end with \n like gettext multi-line
  ;; string convention requires, which is usually not the desirable
  ;; result. To wrap all long lines in msgstr contents of PO file
  ;; currently being edited, use this function instead (shamelessly
  ;; taken from GNUnited Nations manual):
  (defun po-wrap ()
    "Filter current po-mode buffer through `msgcat' tool to wrap all lines."
    (interactive)
    (if (eq major-mode 'po-mode)
        (let ((tmp-file (make-temp-file "po-wrap."))
              (tmp-buf (generate-new-buffer "*temp*")))
          (unwind-protect
              (progn
                (write-region (point-min) (point-max) tmp-file nil 1)
                (if (zerop
                     (call-process
                      "msgcat" nil tmp-buf t (shell-quote-argument tmp-file)))
                    (let ((saved (point))
                          (inhibit-read-only t))
                      (delete-region (point-min) (point-max))
                      (insert-buffer tmp-buf)
                      (goto-char (min saved (point-max))))
                  (with-current-buffer tmp-buf
                    (error (buffer-string)))))
            (kill-buffer tmp-buf)
            (delete-file tmp-file)))))

  ;; If you want auto-fill feature in the sub edit window, try
  ;; longlines-mode. Please turn off auto-fill-mode on the sub edit
  ;; window, or po-mode will add \n to your translated string which is
  ;; usually not what you want. Add this code to your ~/.emacs to
  ;; enable longlines-mode automatically on sub edit window.
  (add-hook 'po-subedit-mode-hook (lambda () (longlines-mode 1)))
  (add-hook 'po-subedit-exit-hook (lambda () (longlines-mode 0)))

  ;; gb-po-mode.el ---  po-mode extensions and fixes
  (when (require 'gb-po-mode nil t)
    )
  )

(provide 'pgo-po-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-po-mode.el ends here
