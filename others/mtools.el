;;; mtools.el --- Emacs front-end to mtools

;; Copyright (C) 2009 LEE Sau dan

;; Author: LEE Sau Dan <sdlee@cs.hku.hk>
;; Version: $Id: mtools.el,v 2.0 2009/12/24 14:20:09 sdlee Exp $
;; Keywords: mtools, dired

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:
;; See the documentation of (function mtools-file-name-handler)

;;; Code:

(require 'dired)

;;;###autoload
(defconst mtools-file-name-prefix-regex "^/mtools/[a-z]:")
(defconst mtools-file-name-prefix "/mtools/")

(defun mtools-strip-prefix (filename)
  (replace-regexp-in-string "^/mtools/" "" filename))

;;;###autoload
(add-to-list 'file-name-handler-alist
	     (cons mtools-file-name-prefix-regex #'mtools-file-name-handler)
	     nil
	     (lambda (x y) (equal (car x) (car y))))

;;;###autoload(makunbound 'mtools-file-name-prefix-regex)


;;;###autoload
(defconst mtools-handlers-alist
  '((file-exists-p . mtools-file-exists-p)
    (file-readable-p . mtools-file-exists-p)
    (file-writable-p . mtools-file-writable-p)
    (file-executable-p . mtools-file-directory-p)
    (file-symlink-p . (lambda (&rest args) nil))
    (file-directory-p . mtools-file-directory-p)
    (file-attributes . mtools-file-attributes)
    (insert-file-contents . mtools-insert-file-contents)
    (insert-directory . mtools-insert-directory)
    (copy-file . mtools-copy-file)
    (rename-file . mtools-rename-file)
    (delete-file . mtools-delete-file)
    (delete-directory . mtools-delete-directory)
    (make-directory-internal . mtools-make-directory-internal)
    (write-region . mtools-write-region)
    (directory-files . mtools-directory-files)
    (dired-compress-file . mtools-compress-file)
    (file-name-completion . mtools-file-name-completion)
    (file-name-all-completions . mtools-file-name-all-completions)
    ))

;;;###autoload
(defun mtools-file-name-handler (operation &rest args)
  "Invoke mtool's file name handler for OPERATION.
First arg specifies the OPERATION, second arg is a list of arguments to
pass to the OPERATION.

To begin with, try \\[find-file] /mtools/a: \\[newline]
\(or any other drive you desire). 
This brings up the `dired' mode.
Many `dired' operations are supported: \\<mtools-dired-map>(keystrokes in parentheses)
  * open (\\[dired-find-file]) or (\\[dired-view-file])
  * copy (\\[dired-do-copy])
  * rename/move (\\[dired-do-rename])
  * delete (\\[dired-flag-file-deletion]) followed by (\\[dired-do-flagged-delete])
  * create directory (\\[dired-maybe-insert-subdir])
  * remove directory (\\[dired-flag-file-deletion])
  * check/change attributes (\\[mtools-do-mattrib])
  * query file type (\\[mtools-show-file-type])
  * change sort order (\\[mtools-change-dired-sort-order])
  * compress/uncompress (\\[dired-do-compress])
\\<global-map>
You can open a file directly by append the pathname to ``/mtools/a:/''
\(e.g. \\[find-file] /mtools/a:/readme.txt \\[newline])
and save it with \\[save-buffer] when you're done with the editing.
It works just like ordinary files.
You can also hit \\<minibuffer-local-filename-completion-map>\\[minibuffer-complete]\\<global-map> to let Emacs complete the file name,
as long as you've typed beyond the drive letter and `:/'.

By default, the `mtools' utilities map drive a: to the first
floppy drive (e.g. `/dev/fd0' on Linux),
and b: to the second drive.
To customize the drive mappings
\(e.g. to access a USB thumb drive, or a [V]FAT file image),
edit /etc/mtools.conf (per system) or ~/.mtoolsrc (per user).
See the info node `(mtools)' for details.

`mtools' makes access to [V]FAT filesystems transparent via
the GNU `mtools' utility
\(see URL `http://www.gnu.org/software/mtools/mtools.html').
It's advantage over mounting via the usual Unix way include:
* usable by unprivileged users without `sudo' or similar utilities,
  as long as the accessed device node grants permissions to the user;
* no need to unmount -- mtools holds the device for its whole transaction
  and releases it when done;  hence, user won't forget to unmount;
  no need to do a ``safely remove device'' operation
"
  (let ((handler (assoc operation mtools-handlers-alist)))
    (if handler
	  (apply (cdr handler) args)
      (let ((inhibit-file-name-handlers
	     (cons #'mtools-file-name-handler
		   (and (eq inhibit-file-name-operation operation)
			inhibit-file-name-handlers)))
	    (inhibit-file-name-operation operation))
	(apply operation args)))))

;;;###autoload
(put 'mtools-file-name-handler
     'operations (mapcar #'car mtools-handlers-alist))

;;;###autoload(makunbound 'mtools-handlers-alist)


(defun mtools-file-exists-p (filename)
  (let* ((mtools-filename (mtools-strip-n-quote filename))
	 (result (mtools-invoke-mtools "mdir" "-a" "-f" "-b" mtools-filename))
	 (exit-status (car result)))
    (eq 0 exit-status)))

(defun mtools-quote-filename (filename &optional skip-last-part)
  (if (not (string-match "^\\([a-z]:\\)\\(.*\\)$" filename))
      filename
    (let ((drive (match-string 1 filename))
	  (directory (match-string 2 filename))
	  filename)

      (if (and skip-last-part
	       (string-match "^\\(.*/\\)\\([^/]+\\)$" directory))
	  (setq filename (match-string 2 directory)
		directory (match-string 1 directory)))
	  
      (concat drive
	      (shell-quote-argument directory)
	      filename))))

(defun mtools-strip-n-quote (filename &optional skip-last-part)
  (mtools-quote-filename (mtools-strip-prefix filename) skip-last-part))

(defun mtools-invoke-mtools (command &rest args)
  (save-excursion
    (set-buffer (get-buffer-create " *mtools*"))
    (setq default-directory temporary-file-directory)
    (erase-buffer)
    (let ((exit-status (apply #'call-process command nil t nil args)))
      (list exit-status (current-buffer)))))

(defun mtools-file-writable-p (filename)
  (or (mtools-file-exists-p filename)
      (let ((parent-dir (directory-file-name
			 (expand-file-name (file-name-directory filename)))))
	(mtools-file-exists-p parent-dir))))

(defconst mtools-mdir-output-regexp
  (concat "^\\(\\(.\\{8\\}\\)"
	  " \\(...\\)"
	  " \\)\\(?:[ 0-9]\\{9,\\}\\|<DIR>    \\)"
	  " ....-..-.."
	  "  ..:.."
	  " \\($\\| \\(.*\\)$\\)"))
(defconst mtools-mdir-8.3-name 1)
(defconst mtools-mdir-name 2)
(defconst mtools-mdir-extension 3)
(defconst mtools-mdir-tail 4)
(defconst mtools-mdir-longname 5)


(defconst mtools-mdir-patched-output-regexp
  (concat "^\\([ 0-9]\\{9,\\}\\|<DIR>    \\)"
	  " \\(\\(....\\)-\\(..\\)-\\(..\\)  \\(..\\):\\(..\\)\\)"
	  "  \\(.+\\)$"))
(defconst mtools-patched-dir-or-size 1)
(defconst mtools-patched-date-time 2)
(defconst mtools-patched-year 3)
(defconst mtools-patched-month 4)
(defconst mtools-patched-day 5)
(defconst mtools-patched-hour 6)
(defconst mtools-patched-minute 7)
(defconst mtools-patched-filename 8)
(defconst mtools-patched-dir-tag "<DIR>    ")


(defun mtools-patch-dir-listing ()
    (goto-char (point-min))
      (while (re-search-forward mtools-mdir-output-regexp nil t)
	(let ((name (match-string mtools-mdir-name))
	      (ext  (match-string mtools-mdir-extension))
	      (longname (match-string mtools-mdir-longname)))
	  (replace-match "" nil t nil mtools-mdir-8.3-name)
	  (if (eq 0 (length longname))
	      (let ((trimmed-name (replace-regexp-in-string " +$" "" name))
		    (trimmed-ext  (replace-regexp-in-string " +$" "" ext)))
		(setq longname 
		      (concat trimmed-name
			      (if (> (length trimmed-ext) 0) ".")
			      trimmed-ext))
		(replace-match (concat " "
				       (propertize longname
						   'dired-filename t))
			       nil t nil mtools-mdir-tail))
	    (add-text-properties (match-beginning mtools-mdir-longname)
				 (match-end mtools-mdir-longname)
				 '(dired-filename t))))))

(defun mtools-file-attributes (filename)
  (let* ((mdir-lookup-string (mtools-strip-prefix
			      (directory-file-name filename)))
	 (fn (file-name-nondirectory mdir-lookup-string))
	 (vfat-attributes
	  (if (string-match "^[a-z]:/?$" mdir-lookup-string)
	      'root
	    (mtools-file-attributes-vfat mdir-lookup-string fn))))

    (cond ((null vfat-attributes) nil)
	  ((eq vfat-attributes 'root)
	   (let ((timestamp (current-time)))
	     (list t nil nil nil timestamp timestamp timestamp
		   nil "drwxrwxrwx" nil nil nil)))
	  (t (let* ((dir-p  (nth 0 vfat-attributes))
		    (size   (nth 1 vfat-attributes))
		    (year   (nth 2 vfat-attributes))
		    (month  (nth 3 vfat-attributes))
		    (day    (nth 4 vfat-attributes))
		    (hour   (nth 5 vfat-attributes))
		    (minute (nth 6 vfat-attributes))
		    (timestamp (encode-time 0 minute hour day month year))
		    (mode  (if dir-p "drwxrwxrwx" "-rw-rw-rw-")))

	       (list dir-p
		     nil nil nil ; link count, uid, gid
		     timestamp timestamp timestamp; access, modify, change
		     size
		     mode
		     nil ; sticky
		     nil nil ; inode number, dev number
		     ))))))

(defun mtools-file-attributes-vfat (mdir-lookup-string filename)
  (let* ((result (mtools-invoke-mtools "mdir" "-a" "-f" 
				       (mtools-quote-filename mdir-lookup-string)))
	 (exit-status (car result))
	 (mtools-buffer (car (cdr result)))
	 (case-fold-search t)
	 )
  (with-current-buffer mtools-buffer
    (mtools-patch-dir-listing)
    (if (mtools-dir-find-entry mdir-lookup-string filename)
	(let* ((dir-or-size (match-string mtools-patched-dir-or-size))
	       (year   (string-to-number (match-string mtools-patched-year)))
	       (month  (string-to-number (match-string mtools-patched-month)))
	       (day    (string-to-number (match-string mtools-patched-day)))
	       (hour   (string-to-number (match-string mtools-patched-hour)))
	       (minute (string-to-number (match-string mtools-patched-minute)))
	       (dir-p (equal mtools-patched-dir-tag dir-or-size))
	       (size  (if dir-p nil (string-to-number dir-or-size))))
	  (list dir-p size year month day hour minute))))))

(defun mtools-dir-find-entry (lookup-string filename)
  ;; pre-condition: buffer (with restrictions) contains mdir output
  ;; post-condition: returns nil if the required entry is not found
  ;;                 resurns 'file if the entry is found as a file entry
  ;;                 resurns 'dir  if the entry is found as the current dir.
  ;;   In case the return value is 'file or 'dir,
  ;;   match data is set up upon returning, corresponding to
  ;;   matching the found entry against `mtools-mdir-patched-output-regexp'.
  ;;   Thus, (match-string mtools-patched-date-time) would return
  ;;   the date-time part of the entry.
  (let (found)
    (goto-char (point-min))
    (while (and (not found)
		(re-search-forward mtools-mdir-patched-output-regexp nil t))
      (setq found
	    (and
		(eq t (compare-strings
		       filename nil nil
		       (match-string mtools-patched-filename) nil nil
		       t))
		'file)))


    (if (not found); is it a directory?
	(let ((regex3 (concat "^Directory for "
			      (regexp-quote lookup-string)
			      "$")))

	  (goto-char (point-min))
	  (if (re-search-forward regex3 nil t)
	      (while (and (not found)
			  (re-search-forward 
			   mtools-mdir-patched-output-regexp nil t))
		(setq found
		      (and
			  (equal mtools-patched-dir-tag
				 (match-string mtools-patched-dir-or-size))
			  (equal "." (match-string mtools-patched-filename))
			  'dir))))))
    found))


(defun mtools-file-directory-p (filename)
  (let* ((attributes (mtools-file-attributes filename))
	 (dir-p (car attributes)))
    dir-p))


(defun mtools-insert-file-contents (filename &optional visit beg end replace)
  (if visit
	  (set-visited-file-name filename))

  (let* ((mtools-filename (mtools-strip-n-quote filename))
	 (r0 (mtools-invoke-mtools "mtype" "-t" mtools-filename))
	 (successful (eq 0 (car r0)))
	 (mtools-buffer (car (cdr r0)))
	 contents len)

    (unless successful
      (signal 'file-error
	      (list (save-excursion
		      (set-buffer mtools-buffer)
		      (buffer-substring-no-properties (point-min) (point-max)))
		    )))

      (if replace
	  (delete-region (point-min) (point-max)))
      (setq contents
	    (save-excursion
	      (set-buffer mtools-buffer)
	      (buffer-substring-no-properties (+ (point-min) (or beg 0))
					      (if end (+ (point-min) end)
						(point-max))))
	    len (length contents))
      (insert contents)

    (if visit
	(progn
	  (set-visited-file-modtime)
	  (set-buffer-modified-p nil)))

    (list filename len)
    ))

(defconst mtools-dired-map
  (let ((map (copy-keymap  dired-mode-map)))
    (mapcar (lambda (replacement)
	      (substitute-key-definition
	       (car replacement) (cdr replacement) map))
	    '((dired-do-chmod . mtools-do-mattrib)
	      (dired-show-file-type . mtools-show-file-type)
	      (dired-sort-toggle-or-edit . mtools-change-dired-sort-order)
	      ))
    (mapcar (lambda (to-suppress)
	      (substitute-key-definition to-suppress 'mtools-undefined map))

	    '(dired-do-shell-command
	      dired-do-chgrp dired-do-chown
	      dired-do-hardlink dired-do-symlink
	      dired-do-hardlink-regexp dired-do-symlink-regexp
	      dired-downcase dired-upcase
	      dired-do-touch
	      dired-diff dired-backup-diff
	      ))
    map))

(defun mtools-undefined ()
  "This `dired-mode' command is not meaningful with `mtools'"
  (interactive)
  (error "command disabled by `mtools'"))
(put #'mtools-undefined 'menu-enable '(not t))


(defvar mtools-sort-by nil
  "Controls the sorting order in `dired' mode buffers generated by `mtools'.
It may take one of the following values:
 * nil => don't sort; use the order listed by the `mdir' command
          (see also info node `(mtools)mdir')
 * name => sort by name (see also `sort-fold-case')
 * date => sort by date and time (latest first)
")
(make-variable-buffer-local 'mtools-sort-by)

(defun mtools-insert-directory (file switches
		      &optional wildcard full-directory-p)
  (let* ((filename (if full-directory-p
		       file
		     (concat default-directory file)))
	 (mtools-filename (mtools-strip-prefix filename))
	 (mtools-buffer (mtools-invoke-mtools-wrapper
			 "mdir" "-a" "-f"
			 (mtools-quote-filename mtools-filename)))
	 (case-fold-search t)
	 (sort-by mtools-sort-by))
      (insert (save-excursion
		(set-buffer mtools-buffer)
		(mtools-patch-dir-listing)
		(if full-directory-p
		    (progn
		      (if sort-by
			  (mtools-sort-dir-listing mtools-buffer sort-by))
		      (buffer-string))

		  (let ((found (mtools-dir-find-entry mtools-filename file)))
		    (cond ((eq found 'file)
			   (concat (match-string 0) "\n"))
			  ((eq found 'dir)
			   (replace-match (propertize file 'dired-filename t)
					  t t nil mtools-patched-filename)
			   (concat (match-string 0) "\n"))
			  (t (error "%s not found" file))))))))
  (if (eq major-mode 'dired-mode)
      (use-local-map mtools-dired-map))
)

(defun mtools-sort-dir-listing (buffer sort-by)
  (with-current-buffer buffer
    (let ((begin (progn
		   (goto-char (point-min))
		   (if (re-search-forward
			mtools-mdir-patched-output-regexp nil t)
		       (match-beginning 0))))
	  (end   (progn
		   (goto-char (point-max))
		   (if (re-search-backward
			mtools-mdir-patched-output-regexp nil t)
		       (match-end 0))))
	  (key-subexp (cond ((eq sort-by 'name) mtools-patched-filename)
			    ((eq sort-by 'date) mtools-patched-date-time)))
	  (reverse (eq sort-by 'date)))
      (if (and begin end key-subexp)
	  (sort-regexp-fields reverse 
			      mtools-mdir-patched-output-regexp
			      (concat "\\" (number-to-string key-subexp))
			      begin end)))))

(defun mtools-change-dired-sort-order ()
  "Change the sort order in an `mtools'-generated `dired' mode buffer.
This rotates the value of the `mtools-sort-by' variable in the order:
 * `nil'
 * name
 * date
"
  (interactive)
  (when (eq major-mode 'dired-mode)
    (setq mtools-sort-by
	  (cond ((null mtools-sort-by) 'name)
		((eq 'name mtools-sort-by) 'date)))

    (setq mode-name
	  (concat "Dired"
		  (if mtools-sort-by
		      (concat " by " (symbol-name mtools-sort-by)))))
    (force-mode-line-update)
    
    (revert-buffer)))

(defun mtools-copy-file (file newname
			 &optional ok-if-already-exists keep-time)
  (let ((args '("-bp")))
    (if ok-if-already-exists (setq args (append args '("-n"))))
    (if keep-time (setq args (append args '("-m"))))
    (apply #'mtools-copy-or-move-file
	   file newname "mcopy" args)))

(defun mtools-copy-or-move-file (file newname mtools-command &rest mtools-opts)
  (let* ((mtools-from (mtools-strip-n-quote file))
	 (mtools-to   (mtools-strip-n-quote newname t)))
    (apply #'mtools-invoke-mtools-wrapper
	   mtools-command (append mtools-opts
				  (list mtools-from mtools-to)))))

(defun mtools-rename-file (file newname &optional ok-if-already-exists)
  (let (args)
    (if ok-if-already-exists (setq args (append args '("-D" "o"))))
    (apply #'mtools-copy-or-move-file
	   file newname "mmove" args)))

(defun mtools-delete-file (filename)
  (mtools-invoke-mtools-wrapper "mdel" (mtools-strip-n-quote filename)))

(defun mtools-delete-directory (directory)
  (mtools-invoke-mtools-wrapper "mrd" (mtools-strip-n-quote directory)))

(defun mtools-invoke-mtools-wrapper (mtools-command &rest mtools-args)
  (let* ((r0 (apply #'mtools-invoke-mtools mtools-command mtools-args))
	 (successful (eq 0 (car r0)))
	 (mtools-buffer (car (cdr r0))))
    (unless successful
      (error "%s when performing %s %s" 
	     (save-excursion
	       (set-buffer mtools-buffer)
	       (buffer-substring-no-properties (point-min) (point-max)))
	     mtools-command
	     mtools-args))
    mtools-buffer))

(defun mtools-make-directory-internal (directory)
  (mtools-invoke-mtools-wrapper "mmd"
				(mtools-strip-n-quote directory t)))

(defun mtools-do-mattrib (filename)
  "Change the FAT attributes of the current file
by invoking program `mattrib' of mtools(1)"
  (interactive (list (dired-get-filename)))
  (let* ((mtools-filename (mtools-strip-n-quote filename))
	 (case-fold-search t)
	 (attribs0 (save-excursion
		     (set-buffer (mtools-invoke-mtools-wrapper
				  "mattrib" "-X" mtools-filename))
		     (goto-char (point-min))
		     (unless (re-search-forward "^\\([ADSHR]*\\)" nil t)
		       (error "bug:|%s|"
			      (buffer-substring-no-properties
			       (point-min) (point-max))))
		     (replace-regexp-in-string "D" "" (match-string 1))))
	 (attribs1 (read-string
		    (format "Change attributes of %s to: " filename)
		    attribs0))
	 (opts (progn
		 (unless (string-match "^[AHRS]*$" attribs1)
		   (error "attributes can only be combinations of [AHRS]"))
		 (mapcar (lambda (attrib)
			   (concat (if (string-match attrib attribs1) "+" "-")
				   attrib))
			 '("A" "H" "R" "S")))))
    
    (apply #'mtools-invoke-mtools-wrapper "mattrib" 
	   (append opts (list mtools-filename)))))

    
(defun mtools-write-region (start end filename
			    &optional append visit lockname mustbenew)
  (if lockname
      (warn "ignoring LOCKNAME(%s), which is not supported by mtools-write-region;" lockname))
  (let ((tempfile (make-temp-file "mtools_save"))
	(ok-if-already-exists
	 (cond ((eq 'excl mustbenew) nil)
	       ((null mustbenew) t)
	       (t (yes-or-no-p (concat "overwrite " filename "?"))))))
    (if append
	(mtools-copy-file filename tempfile t))
    (write-region start end tempfile append 'no-message)
    (mtools-copy-file tempfile filename ok-if-already-exists)

    (if (or (eq visit t) (stringp visit))
	(progn
	  (set-visited-file-modtime)
	  (set-buffer-modified-p nil)))

    (delete-file tempfile))

  (let ((visited-filename (if (stringp visit) visit filename)))
    (set-visited-file-name visited-filename))

  (if (or (eq visit t) (null visit) (stringp visit))
    (message "Wrote file %s" filename)))

(defun mtools-directory-files (directory &optional full match nosort)
  (let* ((mtools-filename (mtools-strip-prefix
			   (file-name-as-directory directory)))
	 (mtools-buffer (mtools-invoke-mtools-wrapper
			 "mdir" "-a" "-f" "-b"
			 (mtools-quote-filename mtools-filename)))
	 (case-fold-search t)
	 (regex (concat "^"
			"\\(" (regexp-quote mtools-filename) "\\)"
			"\\(" ".*" "\\)"
			"$"))
	 result)
    (save-excursion
      (set-buffer mtools-buffer)
      (goto-char (point-min))
      (while (re-search-forward regex nil t)
	(if (or (null match)
		(save-match-data
		  (string-match match (match-string 2))))
	    (setq result
		  (cons (if full
			    (let ((fullname (match-string 0)))
			      (string-match "^[a-z]:" fullname)
			      (replace-match 
			       (concat mtools-file-name-prefix
				       (downcase (match-string 0 fullname)))
			       t t fullname))
			  (match-string 2))
			result)))))
    (reverse result)))

(defun mtools-show-file-type (file)
  "Print the type (according to the `file' command) of FILE for a file
that `mtools' can access.
c.f. `dired-show-file-type'"
  (interactive (list (dired-get-filename)))

 (if (mtools-file-directory-p file)
     (message "%s => directory" file)
  (with-temp-buffer
    (let* ((mtools-filename (mtools-strip-n-quote file))
	   (shell-command (concat "mtype " 
				  (shell-quote-argument mtools-filename)
				  " | file -"))
	   (default-directory temporary-file-directory))
      (call-process-shell-command shell-command nil t t))
    (when (bolp)
      (backward-delete-char 1))
    (goto-char (point-min))
    (if (looking-at "^/dev/stdin:")
	(replace-match (concat file " =>")))
    (message "%s" (buffer-string)))))

(defun mtools-compress-file (file)
  (let* ((extension0 (file-name-extension file))
	 (suffix0 (if extension0 (concat "." extension0) ""))
	 (temp-file0 (make-temp-file temporary-file-directory nil suffix0))
	 (default-directory temporary-file-directory)
	 temp-file1)

    (mtools-copy-file file temp-file0 nil t)
    (setq temp-file1 (dired-compress-file temp-file0))

    (if temp-file1
	(let ((l0 (length temp-file0))
	      (l1 (length temp-file1))
	      file1)
	  (setq file1 (if (> l1 l0)
			  (concat file
				  (substring temp-file1 l0))
			(substring file 0 (- l1 l0))))

	  (mtools-copy-file temp-file1 file1 nil t)
	  (delete-file temp-file1)
	  (mtools-delete-file file)

	  file1)
      (delete-file temp-file0))))


(defun mtools-file-name-all-completions (file directory)
  (let ((regex (concat "^" (regexp-quote file))))
    (mtools-directory-files directory nil regex)))

(defun mtools-file-name-completion (file directory &optional predicate)
  (let* ((regex (concat "^" (regexp-quote file)))
	 (files (mtools-directory-files directory nil regex))
	 (singleton (= 1 (length files)))
	 common-prefix
	 f cmp)
    (while files
      (setq f (car files)
	    files (cdr files))
      (when (and predicate (funcall predicate (expand-file-name f directory)))
	(if (null common-prefix)
	    (setq common-prefix f)

	  (setq cmp (compare-strings
		     common-prefix nil nil
		     f nil nil
		     t))
	  (unless (eq t cmp)
	    (setq common-prefix (substring common-prefix 0 (1- (abs cmp))))))
	))

    (if (and singleton
	     (= (length common-prefix) (length file)))
	t
      common-prefix)))
    


(provide 'mtools)

;;; mtools.el ends here
