;;; tracker.el --- Interface to Gnome tracker command

;; Copyright (C) 2007 Pavol Murin

;; Author: Pavol Murin <radostky dot slovenskoo gmail com>
;; Keywords: data

(require 'org)

(defvar tracker-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(control ?a)] 'beginning-of-line)
    (define-key map [(control ?e)] 'end-of-line)
    (define-key map [(control ?n)] 'next-line)
    (define-key map [(control ?p)] 'previous-line)
    (define-key map [??] 'describe-mode)
    (define-key map [?q] 'bury-buffer)
    (define-key map [?n] 'org-next-link)
    (define-key map [?p] 'org-previous-link)
    (define-key map (kbd "TAB") 'org-next-link)
    (define-key map (kbd "RET") 'org-open-at-point)
    (define-key map [?o] 'org-open-at-point)
    (define-key map [(control ?o)] 'org-open-at-point)
    (define-key map [?m] 'tracker)
    map)
  "Keymap for `tracker-mode'.")

(define-derived-mode tracker-mode org-mode "tracker"
  "tracker results browser"
  (use-local-map tracker-mode-map)
  (set (make-local-variable 'org-startup-folded) nil)
  (toggle-read-only 1))



(defun call-tracker (text buffer-name)
  "calls the tracker-search command with passed-in text as parameter. Collects all results in the buffer *tracker-all-results*"
  (call-process "tracker-search" nil buffer-name nil text))

(defun is-file-in-directory (filename directory)
  "returns t if the filename is bellow the directory, nil if not"
  (let ((dir-of-file (file-name-directory (expand-file-name filename)))
	(dir (expand-file-name directory)))
    (eq 0 (string-match dir dir-of-file))))

(defun filter-files-in-dir (filenames directory)
  "returns a list of only those filenames that are under directory"
  (remove-if-not (lambda (f) (is-file-in-directory f directory)) filenames))

;; test cases:
;(is-file-in-directory "/a/b/c" "/a/b/")
;(is-file-in-directory "/a/b2/c" "/a/b/")

;;(filter-files-in-dir (list "/a/b/c" "/a/b2/c" "/a/bc/d") "/a/b")
;; oh no! this was tested on windows!
(filter-files-in-dir `("c:/Documents and Settings/pmurin/Application Data/f" "~/f" "/home/another/f") "~/")

;;`("c:/Documents and Settings/pmurin/Application Data/f" "~/f")

;;(filter-files-in-dir (list "/usr/lib/a" "/usr/lib2/a" "/usr/lib/ab") "/usr/lib/")

(defun format-line-tracker-mode (line)
  (concat "* " (org-make-link-string (concat "file:" line) line)))

(defun tracker (text dir)
  "search with tracker and filter results only in dir"
  (interactive "sFind text: \nDFind %s in directory: ")
  (let ((b (get-buffer-create "*tracker-all-results*")))
    (with-current-buffer b
      (toggle-read-only -1)
      (delete-region (point-min) (point-max))
      (call-tracker text (buffer-name b))
      (let ((result (mapconcat (lambda (line) (format-line-tracker-mode line))
			       (filter-files-in-dir (split-string (buffer-string-by-name (buffer-name b))) dir)
						   "\n")))
	(delete-region (point-min) (point-max))
	(insert result)
	(goto-char (point-min))
   (tracker-mode)))))

;; more testing
;(filter-files-in-dir `("/home/muro/develop/firstdev" "/home/muro/develop/seconddev") "/home/muro")
(tracker "asd" "f:")


(provide 'tracker)
;;; tracker.el ends here