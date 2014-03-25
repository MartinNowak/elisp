;;; auto-arg-mode.el -- makes numbers prefixes by default.

;; Copyright (C) 1998 Anders Lannerbäck

;; Author:  Anders Lannerbäck <ande...@altavista.net> or <f95-...@nada.kth.se>
;; Created: 4 Sep 1998
;; Version: 0.9
;; Keywords: Prefix minor mode  

;; Auto-arg-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later version.

;; Auto-arg-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;;; Commentary:

;; This is a minor mode for people who uses numbers as prefixes more often than
;; to insert them in text. With this minor mode entering a number is roughly
;; equivalent to entering C-u <number>.

;; Examples: Entering "3" will not insert 3 in the text but rather wait for the
;; next key. The echo area will show "3" so you know what you are doing. If you
;; then enter "1" the echo area will show "31". Entering <SPC> at this point
;; will insert the number 31 at point in the buffer (but no space), but if you
;; enter any other key sequence, such as "C-f" or "p" it will be repeated 31
;; times. Thus "31<SPC>" yields "31", and "31p" yields
;; "ppppppppppppppppppppppppppppppp".

;;; Change log:
;; 5 sep 1998 version 0.2  --  total rewrite.
;; 4 sep 1998 version 0.1

;;; Code:

(defvar auto-arg-mode-modeline-string " auto-arg ")
(defvar auto-arg-mode-map (copy-keymap (current-local-map)))
(defvar auto-arg-mode-original-map (copy-keymap (current-local-map)))
(defvar auto-arg-mode nil)
(make-variable-buffer-local 'auto-arg-mode)
(or (assq 'auto-arg-mode minor-mode-alist)
    (setq minor-mode-alist
          (cons '(auto-arg-mode auto-arg-mode-modeline-string) minor-mode-alist)))

(defun auto-arg-mode (arg)
  "Toggle auto argmode.
With arg, turn auto arg mode on iff arg is positive."
  (interactive "P")
  (setq auto-arg-mode
        (if (null arg) (not auto-arg-mode)
          (> (prefix-numeric-value arg) 0)))
  (if auto-arg-mode
      (use-local-map auto-arg-mode-map)
    (use-local-map auto-arg-mode-original-map))
  (force-mode-line-update))

(defun auto-arg-prefixer (arg)
  (interactive "P")
  (let* (( s (this-command-keys))
         (l (length s))
         (n (string-to-number (substring s (- l 1) l))))
    (message "%d"
             (setq prefix-arg
                   (if arg
                       (+ (* arg 10) n)
                     n)))))

(defun auto-arg-terminator (arg)
  (interactive "P")
  (if arg
      (insert (number-to-string arg))
    (insert (this-command-keys))))

(define-key auto-arg-mode-map "1" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "2" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "3" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "4" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "5" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "6" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "7" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "8" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "9" 'auto-arg-prefixer)
(define-key auto-arg-mode-map "0" 'auto-arg-prefixer)
(define-key auto-arg-mode-map " " 'auto-arg-terminator)

;;; auto-arg.el ends here
