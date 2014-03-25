;;; pgo-comint.el --- Setup comint.
;;
;; Filename: pgo-comint.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: fre okt 16 12:16:26 2009 (+0200)
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
;;   Required feature `pgo-comint' was not provided.
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

;; comint
;; The next set of customizations I added modified the behaviour of
;; shell modes. The first one will cause cycling to skip unique
;; values; if you run the same command twice, M-p twice will take
;; you to a different commands. The other two are fairly
;; self-explanatory, and are for showing as much as possible in the
;; buffer.
(setq comint-input-ignoredups t)
(setq comint-scroll-show-maximum-output nil)
(setq comint-scroll-to-bottom-on-input t)

(add-hook 'comint-mode-hook ;; 'comint-load-hook
          (lambda ()
            ;;   (if delete-selection-mode
            ;;       (put 'comint-delchar-or-maybe-eof 'delete-selection 'supersede))
            (local-set-key [(meta up)] 'comint-previous-prompt)
            (local-set-key [(meta down)] 'comint-next-prompt)
            ))

(defun xsteve/comint-send-string(cmd)
  (interactive "sSend Command: ")
  (comint-goto-process-mark)
  (when (> (point-max) (point))
    (kill-line))
  (insert cmd)
  (comint-send-input))

(provide 'pgo-comint)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-comint.el ends here
