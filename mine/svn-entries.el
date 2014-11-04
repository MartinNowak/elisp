;;; svn-entries.el - Parsing contents of .svn/entries file.
;; Author: Per Nordlöw <per.nordlow@gmail.com>

(defconst svn-entries-regexp
  (rx (group (* nonl)) "\n")
  "Subversion .svn/entries lines match regexp.")

(defconst svn-entries-multi-regexp
  (rx (group (* nonl)) "\n"
      (group (* nonl)) "\n"
      (group (* nonl)) "\n"
      (group (* nonl)) "\n"
      )
  "Subversion .svn/entries lines match regexp.")
;; Use: (cscan-buffer svn-entries-regexp (get-buffer "entries") 0 t nil t 'string)
;; Use: (cscan-file "~/.gdb/printers/.svn/entries" svn-entries-regexp 0 t nil nil t nil 'string)

(defun tscan-directory-svn-string (asub)
  ;;TODO Use `dcache-rget-fcache' instead.
  ;; Instead use `with-temp-buffer' and `find-file-noselect' and `re-search-forward'
  (when nil
    (let ((scan (ignore-errors (cscan-file-uncached (expand-file-name ".svn/entries" asub)
                                                    svn-entries-regexp 0 t nil t nil 'string))))
      (concat " (SVN:"
              (match-string 1)
              (match-string 2)
              (match-string 3)))))
;; Use: (tscan-directory-svn-string "~/.gdb/printers")
;; Use: (progn (dcache-reset) (tscan-directory-svn-string "~/.gdb/printers"))

(provide 'svn-entries)
