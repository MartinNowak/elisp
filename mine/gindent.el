;;; gindent.el - Emacs Interface to external command GNU indent

;; See http://en.wikipedia.org/wiki/Indent_style for Indentation styles

;;(setq dummy (make-hash-table :test 'equal))
;;(puthash "GNU" "-gnu" dummy)
;;(hash-table-size dummy)
;;(try-completion "G" dummy)

(defgroup gindent nil
  "Interface to GNU Indent."
  :group 'tools)

(defvar gindent-name-last "GNU")
(defvar gindent-name-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'gindent-name-history t))

(defvar gindent-flags "-br -ce -npcs -c32")

;; (concat "-st -bad --blank-lines-after-procedures -bli0 -i4 "
;;         "-l79 -ncs -npcs -nut -npsl -fca -lc79 -fc1")

(defconst gindent-styles-alist
  '(
    ("GNU" "--gnu-style")
    ("Kernighan & Ritchie" "--k-and-r-style")
    ("Berkeley" "")
    ("Stroustrup" "-i4 -bls -bl -bli0 -saf -sai -saw -c32 -bli0 -lp -ppi2")
    ("BSD/Allman" "")
    ("Nordlöw" "-i2 -br -ce -npcs -c32 -ppi2")
    )
  "C Code Indentation Styles.
See http://en.wikipedia.org/wiki/Indent_style"
  )
;; Use: (cdr (assoc "GNU" gindent-styles-alist))
;; Use: (cdr (assoc "Kernighan & Ritchie" gindent-styles-alist))
;; Use: (cdr (assoc "Stroustrup" gindent-styles-alist))

(defun gindent-read-style (&optional prompt)
  "Read C Indentation Style from minibuffer."
  (interactive)
  (let ((completion-ignore-case t)
        (name (completing-read
               (or prompt "Style: ") gindent-styles-alist nil t
               gindent-name-last
               'gindent-name-history
               gindent-name-last)))
    (setq gindent-name-last name)
    (cadr (assoc name gindent-styles-alist))))
;; Use: (gindent-read-style)

(defun gindent-region (buffer)
  "Indent C/C++ BUFFER's region from START to END using the
external program GNU indent."
  (interactive "bBuffer (to indent): ")
  (if (executable-find "indent")
      (let ((flags (gindent-read-style)))
        (save-buffer)
        (shell-command-on-region (region-beginning) (region-end)
                                 (concat "indent" " " flags)
                                 buffer t))))
;; Use: (gindent-region buffer-file-name)

(defun gindent-buffer (buffer)
  "Indent C/C++ Buffer using the external program GNU indent."
  (interactive "bBuffer (to indent): ")
  (mark-whole-buffer)
  (gindent-region buffer)
  )
;; Use: (gindent-buffer nil)

(defun gindent-file (file out-file)
  "Indent C/C++ Source or Header FILE using the external program GNU indent and put result in OUT-FILE."
  (interactive "fSource file (to indent): \nFOutput file (from indent): ")
  (gindent-read-style)
  (if (executable-find "indent")
      (progn
        (shell-command (concat "indent"
                               " " gindent-flags
                               " " file
                               " -o " out-file))
        (find-file out-file)
        )
    (message "Program indent not found")))

(global-set-key [(control c) (I) (b)] 'gindent-buffer)
(global-set-key [(control c) (I) (f)] 'gindent-file)

;; Add it to the "Tools" menu
(define-key menu-bar-tools-menu [gindent-buffer]
  '(menu-item "Tidy C/C++ Buffer (GNU Indent)..." gindent-buffer
              :help "Indent a C or C++ Source Buffer using GNU indent"))

;; Add it to the "Tools" menu
(define-key menu-bar-tools-menu [gindent-file]
  '(menu-item "Tidy C/C++ File (GNU Indent)..." gindent-file
              :help "Indent a C or C++ Source File using GNU indent"))

(provide 'gindent)
