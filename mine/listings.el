;;; listings.el --- Listings of various kinds.
;; Author: Per Nordlöw

;; ===========================================================================
;; Here is a function to list overlays at point in Emacs
;; interactively as with ´list-text-properties-at':

(defun list-overlays-at-point (&optional pos)
  "Describe overlays at POS or point."
  (interactive)
  (setq pos (or pos (point)))
  (let ((overlays (overlays-at pos))
        (obuf (current-buffer))
        (buf (get-buffer-create "*Overlays*"))
        (props '(priority window category face mouse-face display
                          help-echo modification-hooks insert-in-front-hooks
                          insert-behind-hooks invisible intangible
                          isearch-open-invisible isearch-open-invisible-temporary
                          before-string after-string evaporate local-map keymap
                          field))
        start end text)
    (if (not overlays)
        (message "None.")
      (set-buffer buf)
      (erase-buffer)
      (dolist (o overlays)
        (setq start (overlay-start o)
              end (overlay-end o)
              text (with-current-buffer obuf
                     (buffer-substring start end)))
        (when (> (- end start) 13)
          (setq text (concat (substring text 1 10) "...")))
        (insert (format "From %d to %d: \"%s\":\n" start end text))
        (dolist (p props)
          (when (overlay-get o p)
            (insert (format " %15S: %S\n" p (overlay-get o p))))))
      (pop-to-buffer buf))))
(defalias 'list-overlays-at 'list-overlays-at-point)
;; ToDo: (list-overlays-at)

;; ===========================================================================
;; List C and C++ Operators

(defun list-c-c++-operators ()
  "Print a table of C and C++ Operators Precedence and Associativity."
  (interactive)
  (if (buffer-exists-p "*C and C++ Operators*")
      (switch-to-buffer "*C and C++ Operators*" t)
    (progn
      (switch-to-buffer "*C and C++ Operators*" t)
      (erase-buffer)
      (insert-file-contents-literally (elsub "mine/OPERATORS.txt") t)
      (goto-char (point-min))

      ;; forge previous undos
      (buffer-disable-undo)
      (buffer-enable-undo)
      (setq buffer-read-only t)        ;make buffer read-only (unreadable)

      ;;(lock-buffer)
      (when (require 'operators-mode nil t)
        (operators-mode))
      )
    ))
(defalias 'c-list-operators 'list-c-c++-operators)

;; ===========================================================================
;; Show ASCII-Table
;; URL: http://www.emacswiki.org/cgi-bin/wiki.pl?AsciiTable
;; TODO Merge with ascii-table.el

(defun list-ascii-table ()
  "Display basic ASCII table (0 thru 128)."
  (interactive)
  (switch-to-buffer "*ASCII Table*" t)
  (erase-buffer)
  (save-excursion (let ((i -1))
                    (insert "ASCII characters 0 thru 127.\n\n")
                    (insert "Hex Dec Char| Hex Dec Char| Hex Dec Char| Hex Dec Char\n")
                    (insert "--- --- ----| --- --- ----| --- --- ----| --- --- ----\n")
                    (while (< i 31)
                      (insert (format "%3x %3d %3s | %3x %3d %3s | %3x %3d %3s | %3x %3d %3s\n"
                                      (setq i (+ 1  i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)))
                      (setq i (- i 96))))))

(defun list-ascii-table-optional (&optional limit base)
  "Print the ASCII table (up to char 127).

Given the optional argument LIMIT, print the characters up to char
LIMIT.  Try 254 for example.

Optional argument BASE can be either 8 for octal, 10 for decimal, or
16 for hex."
  (interactive "P")
  (switch-to-buffer "*ASCII*" t)
  (erase-buffer)
  (let ((fmt (cond ((eq base 16) "0x%02x %4s")
                   ((eq base 8) "$%03o %4s")
                   (t "%4d %4s")))
        (i 0))
    (setq limit (or limit 127))
    (insert (format "ASCII characters up to number %d" limit))
    (center-line)
    (insert "\n\n")
    (while (<= i limit)
      (insert (format fmt i (single-key-description i)))
      (setq i (+ i 1))
      (if (= 0 (mod i 6))
          (newline)
        (insert "   "))))
  (goto-char (point-min))
  (setq buffer-read-only t)        ;make buffer read-only (unreadable)
  )

(defalias 'list-ascii-table-decimal 'list-ascii-table-optional)

(defun list-ascii-table-octal (&optional limit)
  "Print the ascii table up to LIMIT (default is 0177)."
  (interactive "P")
  (list-ascii-table-optional limit 8))

(defun list-ascii-table-hex (&optional limit)
  "Print the ascii table up to LIMIT (default is 0x7f)."
  (interactive "P")
  (list-ascii-table-optional limit 16))

(provide 'listings)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; listings.el ends here
