;;; dired-sort-map.el --- in Dired: press s then s, x, t or n to sort by Size, eXtension, Time or Name
;; Inspired by Francis J. Wright's dired-sort-menu.el

(require 'dired)

(defvar dired-sort-map (make-sparse-keymap))

(defun dired-sort-on-size ()
  "Sort by size."
  (interactive)
  (dired-sort-other (concat dired-listing-switches "S"))
  (message "Sorted on size"))

(defun dired-sort-on-extension ()
  "Sort by eXtension."
  (interactive)
  (dired-sort-other (concat dired-listing-switches "X"))
  (message "Sorted on extension"))

(defun dired-sort-on-modification-time ()
  "Sort by modification time."
  (interactive)
  (dired-sort-other (concat dired-listing-switches "ct"))
  (message "Sorted on modification time"))

(defun dired-sort-on-access-time ()
  "Sort by access time."
  (interactive)
  (dired-sort-other (concat dired-listing-switches "at"))
  (message "Sorted on access time"))

(defun dired-sort-on-name ()
  "Sort by name."
  (interactive)
  (dired-sort-other dired-listing-switches)
  (message "Sorted on name"))

(defun dired-sort-on-name-group-dirs ()
  "Sort by name grouping directories."
  ()
  (dired-sort-other (concat dired-listing-switches " --group-directories-first"))
  (message "Sorted on name grouping directories"))

(let ((map dired-sort-map))
  (define-key dired-mode-map "s" map)
  (define-key map "s" 'dired-sort-on-size)
  (define-key map "x" 'dired-sort-on-extension)
  (define-key map "t" 'dired-sort-on-modification-time)
  (define-key map "a" 'dired-sort-on-access-time)
  (define-key map "n" 'dired-sort-on-name)
  (define-key map "d" 'dired-sort-on-name-group-dirs))

(when (require 'filedb nil t)
  (defun dired-sort-on-type ()
    "Sort by File Type (given by filedb)."
    (interactive)
    (dired-sort-other (concat dired-listing-switches "t"))
    (message "Sorted on file category (type)"))
  (define-key dired-sort-map "c" 'dired-sort-on-name-group-dirs))

(provide 'dired-sort-map)
