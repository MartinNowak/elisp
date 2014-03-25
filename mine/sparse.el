;;; sparse.el --- Interface to Semantic Parse (Sparse)
;; Author: Per Nordlöw
;; coding: utf-8

(provide 'sparse)

(defvar sparse-name-current "GNU")
(defvar sparse-name-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'sparse-name-history t))

(defvar sparse-flags "-br -ce -npcs -c32")

(defconst sparse-warnings-alist
  '(
    ("GNU" "--gnu-style")
    )
  "Sparse Warnings"
  )
;; Use: (cdr (assoc "GNU" sparse-warnings-alist))

(defun sparse-read-name-flags ()
  "Read Sparse Warning Flags from minibuffer."
  (interactive)
  (let ((completion-ignore-case t)
	(prompt "Style: "))
    (cadr (assoc (completing-read prompt sparse-warnings-alist nil t
                                 sparse-name-current
                                 'sparse-name-history
                                 sparse-name-current) sparse-warnings-alist))))
;; Use: (sparse-read-name-flags)

(defun sparse-region (buffer)
  "Analyze C/C++ BUFFER's region from START to END using the
external program Sparse."
  (interactive "bBuffer (to analyze): ")
  (if (executable-find "sparse")
      (let ((flags (sparse-read-name-flags)))
        (save-buffer)
        (shell-command-on-region (region-beginning) (region-end)
                                 (concat "sparse" " " flags)
                                 buffer))))
;; Use: (sparse-region buffer-file-name)

(defun sparse-buffer (buffer)
  "Analyze C/C++ Buffer using the external program Sparse."
  (interactive "bBuffer (to analyze): ")
  (mark-whole-buffer)
  (sparse-region buffer)
  )
;; Use: (sparse-buffer nil)

(defun sparse-file (file out-file)
  "Analyze C/C++ Source or Header FILE using the external program
Sparse and put result in OUT-FILE."
  (interactive "fSource file (to sparse): \nFOutput file (from sparse): ")
  (sparse-read-name-flags)
  (if (executable-find "sparse")
      (progn
	(shell-command (concat "sparse"
			       " " sparse-flags
			       " " file
			       " -o " out-file))
	(find-file out-file)
	)
    (message "Program sparse not found")))

(global-set-key [(control c) (meta s) (b)] 'sparse-buffer)
(global-set-key [(control c) (meta s) (f)] 'sparse-file)

;; Add it to the "Tools" menu
(define-key menu-bar-tools-menu [sparse-buffer]
  '(menu-item "Check C/C++ Buffer (Sparse)..." sparse-buffer
	      :help "Check a C or C++ Source Buffer using sparse"))

;; Add it to the "Tools" menu
(define-key menu-bar-tools-menu [sparse-file]
  '(menu-item "Check C/C++ File (Sparse)..." sparse-file
	      :help "Check a C or C++ Source File using Sparse"))
