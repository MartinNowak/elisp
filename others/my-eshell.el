;;; my-eshell.el - my eshell additions

;; Copyright (C) 1997-2000 Free Software Foundation, Inc.

;; Author: Kevin A. Burton (burton@openprivacy.org)
;; Maintainer: Kevin A. Burton (burton@openprivacy.org)
;; Location: http://relativity.yi.org
;; Keywords: 
;; Version: 1.0.0

;; This file is [not yet] part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; TODO:
;;        - 'eshell' should always goto the first created console.
;;
;;        - need to correctly escape ansi colors.  If I end up using "su" this
;;        breaks eshell because I use ansi escape colors :(
;;
;;        - method to jump between consoles.  
;;       
;;        - problems: clear doesn't work.  Provide my own impl of clear???
;;
;;        - disable dynamic completion
;;
;;        - add a basic function for ^D terminal exit like xterm.
;;
;; eshell-aliases-file

(load-library "eshell-auto")

(defun eshell-smart-exit()
  "If the cursor is not on the prompt... place it there.  If there is a command
being entered... use backward-kill-word on it.  ...else exit the terminal."
  
  (interactive)

  ;;if we aren't within the prompt... go there.
  (let(current-line prompt-line)
    (save-excursion

      (setq current-line (count-lines (point-min) (point)))

      (goto-char (point-max))
      (eshell-bol)
      (setq prompt-line (count-lines (point-min) (point))))
    
    (if (not (= current-line prompt-line))
        (progn 
          (goto-char (point-max))
          (eshell-bol)
          (goto-char (point-at-eol)))

      ;;else we are already within the prompt...
      (progn 
        (save-excursion
          
          (let(begin end prompt-line)
            
            (goto-char (point-max))
            (eshell-bol)
            
            (setq begin (point))
            
            (goto-char (point-at-eol))
            
            (setq end (point))
            
            (if (= begin end)
                (progn 
                  ;;insert exit just to show the user what is happening.
                  (insert "exit")
                  (eshell-send-input))
              (progn
                (backward-kill-word 1)))))))))

(defun eshell/clear()
  "Quickly clear the terminal.  Just like the unix command clear."

  (message "eshell/clear")
  
  (setq inhibit-read-only t)
  
  (delete-region (point-min) (point-max))
  (setq inhibit-read-only nil)

  (eshell-emit-prompt))
  
(defun eshell-scroll-to-end()
  "Called to make sure that the prompt is at the end of the screen"
  (interactive)

  ;;now make sure the point is located at the end of the buffer
  (goto-char (point-max))
  (eshell-bol)

  (let(window-start)

    (save-excursion

      (goto-char (point-max))
      (goto-char (point-at-bol))
      
      (forward-line (+ (* (window-height) -1) 3))

      (setq window-start (point)))

    (set-window-start (selected-window) window-start)))

(add-hook 'eshell-after-prompt-hook 'eshell-scroll-to-end)

(provide 'my-eshell)
