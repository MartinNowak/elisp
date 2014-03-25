;;; caml-info-look.el --- automatically lookup OCaml Info files.

;; Copyright © 2002 Olivier Andrieu <o_andrieu@netcourrier.com>

;; Version: 0.9
;; URL: http://oandrieu.nerim.net/ocaml/index.html#odoc

;;; Commentary:

;; Set `caml-info-lookup-info-files' to be a list of Info files
;; produced by Ocamldoc's Texinfo generator (you can use
;; `caml-info-lookup-add-file' to do this). If the filenames do not
;; contain absolute paths, the files will be searched in
;; `Info-directory-list'.  
;; Use `caml-info-lookup-id' to lookup an identifier (bound to [C-c h]
;; in caml-mode).
;; `caml-info-lookup-rescan' (bound to [C-c r]) rescans the current
;; file for opened modules and module aliases.

;; uses code from info-look.el (part of GNU Emacs) 
;; by Ralph Schleicher <rs@purple.UL.BaWue.DE>, Copyright FSF

;;; Changes:
;; 0.9
;;   bugfix in caml-info-lookup-scan-aliases
;; 0.8
;;   keybindings in `eval-after-load'
;; 0.7:
;;   Added keybindings for inferior-caml-mode
;;   set case-fold-search to nil in the inferior-caml-mode hook
;; 0.6:
;;   Module aliases work with multiples modules (and functors).
;; 0.5:
;;   Works better with methods. Other bugfixes.
;; 0.4:
;;   Support for opened modules and module aliases
;; 0.3:
;;   Looking for inexistant entry A.smthg now produces an error instead of
;;   showing B.smthg .
;; 0.2:
;;   Fixed a bug when using more than one Info file.
;; 0.1:
;;   Initial release.

;;; Code:

(require 'cl)
(require 'info)

(defvar caml-info-lookup-info-files '("ocaml")
  "List of Ocamldoc-generated Info files to search.")

(defvar caml-info-lookup-other-window-flag t
  "Non-nil means pop up the Info buffer in another window.")

(defvar caml-info-lookup-highlight-face 'highlight
  "Face for highlighting looked up help items.
Setting this variable to nil disables highlighting.")



(defvar caml-info-lookup-opened-modules '()
  "alist of opened modules per file")

(defvar caml-info-lookup-module-aliases '()
  "alist of opened module aliases per file")

(defvar caml-info-lookup-highlight-overlay nil
  "Overlay object used for highlighting.")

(defvar caml-info-lookup-history nil
  "History of previous input lines.")

(defvar caml-info-lookup-cache (make-hash-table :test 'equal)
  "Cache storing data maintained automatically by the program.")

(defconst caml-info-lookup-info-indices
  (mapcar (lambda (s) (concat s " index"))
	  '("Types" "Exceptions" "Values" "Class attributes" "Methods" 
	    "Classes" "Class types" "Modules" "Module types"))
  "The indices to search in the info files")

(defun caml-info-lookup-reset ()
  "Throw away all cached data."
  (interactive)
  (message "Clearing caml-info-lookup cache")
  (clrhash caml-info-lookup-cache))

(defun caml-info-lookup-add-file (file)
  "Add a file to the list of info files to search and flush the cache"
  (interactive "FInfo file: ")
  (add-to-list 'caml-info-lookup-info-files file)
  (caml-info-lookup-reset))

(defun caml-info-lookup-rescan ()
  "(re)scan a file, looking for modules aliases and opened modules"
  (interactive)
  (caml-info-lookup-scan-open)
  (caml-info-lookup-scan-aliases))

(defun caml-info-lookup-build-cache (&optional clear)
  "Builds the cache."
  (when clear (caml-info-lookup-reset))
  (when (zerop (hash-table-count caml-info-lookup-cache))
    (with-temp-buffer 
      (Info-mode)
      (let ((files caml-info-lookup-info-files)
	    file indices node entry modules)
	(while files
	  (setq file (car files))
	  (when (condition-case nil
		    (Info-goto-node (concat "(" file ")Top"))
		  (error (message "Cannot access Info file `%s'..." file)))
	    (setq indices caml-info-lookup-info-indices)
	    (while indices
	      (setq node (concat "(" file ")" (car indices)))
	      (when 
		  (condition-case nil
		      (Info-goto-node node)
		    (error nil))
		(condition-case nil
		    (progn
		      (message "Processing Info node `%s'..." node)
		      (goto-char (point-min))
		      (and (search-forward "\n* Menu:" nil t)
			   (while (re-search-forward 
				   "\n\\* \\([^: ]*\\)\\( <[0-9]+>\\)?: *\\([^.]*\\)\\." nil t)
			     (setq entry (match-string 1)
				   modules (split-string (match-string 3) "/"))
			     (let* ((cache-data 
				     (gethash entry caml-info-lookup-cache))
				    (file-data
				     (assoc file cache-data)))
			       (if (not file-data)
				   (setf (gethash entry caml-info-lookup-cache)
					 (cons (cons file (cons modules nil)) cache-data))
				 (unless (member modules (cdr file-data))
				   (setcdr file-data
					   (cons modules (cdr file-data))))))
			     )))
		  (error 
		   (message "Error processing Info node `%s'..." node)
		   nil)))
	      (setq indices (cdr indices))))
	  (setq files (cdr files))) ))
    (maphash
     (lambda (key data)
       (while data
	 (let ((file-data (car data)))
	   (setcdr file-data
		   (sort (cdr file-data)
			 (lambda (mla mlb)
			   (let ((la (length mla)) (lb (length mlb)))
			     (if (= la lb)
				 (string< (car mla) (car mlb))
			       (< (length mla) (length mlb))))))))
	 (setq data (cdr data))))
     caml-info-lookup-cache)
    (hash-table-count caml-info-lookup-cache)
    ))

(defun caml-info-lookup-format (filen modules)
  (concat "(" filen ")" (mapconcat 'identity modules "/")))

; eurk !
(defun flatten-list (li)
  (let (fli)
    (while li
      (setq fli (append fli
			(if (listp (car li))
			    (car li)
			  (list (car li)))))
      (setq li (cdr li)))
    fli))

(defun caml-info-lookup-replace-aliases (modules)
  (let ((aliases (cdr (assoc (buffer-name) caml-info-lookup-module-aliases))))
    (if (not aliases)
	modules
      (flatten-list 
       (mapcar
	'(lambda (m)
	   (or (cdr (assoc m aliases))
	       m))
	modules))
      )))

(defun caml-info-lookup-choose-modules-method (cache-data)
  ;; very dumb: just pick the first entry for the first file ...
  (let ((entry (car cache-data)))
    (caml-info-lookup-format 
     (car entry) (cadr entry))))

(defun caml-info-lookup-choose-modules 
  (entry-modules cache-data &optional norecurs)
  (or
   ; first, try some opened modules
   (unless norecurs
     (let (found
	   (omods (cdr (assoc (buffer-name) caml-info-lookup-opened-modules))))
       (while (and omods (not found))
	 (setq found
	       (caml-info-lookup-choose-modules
		(cons (car omods) entry-modules) cache-data t))
	 (setq omods (cdr omods)))
       found))
   (or
    (if entry-modules
	(catch 'found
	  (setq entry-modules 
		(caml-info-lookup-replace-aliases entry-modules))
	  (let ((file cache-data))
	    (while file
	      (let ((cache-m (cdar file)))
		(while cache-m	       
		  (if (equal entry-modules (car cache-m))
		      (throw 'found 
			     (caml-info-lookup-format 
			      (caar file) (car cache-m))))
		  (setq cache-m (cdr cache-m))))
	      (setq file (cdr file)))))
      ;; if no modules specified, try Pervasives
      (caml-info-lookup-choose-modules '("Pervasives") cache-data t))
    ;; nothing found, report an error
    (unless norecurs
      (error "could not locate module")))))

(defun caml-info-lookup (entry modules &optional method)
  "Display the documentation of a help item."
  (caml-info-lookup-build-cache)
  (let ((cache-entry (gethash entry caml-info-lookup-cache))
	(window (selected-window))
	node)
    (if (not cache-entry)
	(error "id not in index"))
    (setq node 
	  (if method
	      (caml-info-lookup-choose-modules-method cache-entry)
	    (caml-info-lookup-choose-modules modules cache-entry nil)))
    (if (not caml-info-lookup-other-window-flag)
	(info)
      (save-window-excursion (info))
      (switch-to-buffer-other-window "*info*"))
    (when (condition-case nil
	      (Info-goto-node node)
	    (error 
	     (message "Cannot access Info node %s" node)
	     (sit-for 1)
	     nil))
      (condition-case nil
	  (progn
	    (setq case-fold-search nil)
	    (goto-char (point-min))
	    (re-search-forward
	     (concat "^ - \\(val\\( mutable\\)?\\|method\\|\\(class\\|module\\)\\( type\\)?\\|type\\|exception\\) *" (regexp-quote entry) "[ \t\n]"))
	    (goto-char (match-beginning 0))
	    (recenter 1)
	    (and window-system caml-info-lookup-highlight-face
		 ;; Search again for ITEM so that the first
		 ;; occurence of ITEM will be highlighted.
		 (re-search-forward (regexp-quote entry))
		 (let ((start (match-beginning 0))
		       (end (match-end 0)))
		   (if (overlayp caml-info-lookup-highlight-overlay)
		       (move-overlay caml-info-lookup-highlight-overlay
				     start end (current-buffer))
		     (setq caml-info-lookup-highlight-overlay
			   (make-overlay start end))))
		 (overlay-put caml-info-lookup-highlight-overlay
			      'face caml-info-lookup-highlight-face)))
	(error nil)))
    ;; Don't leave the Info buffer if the help item couldn't be looked up.
    (if caml-info-lookup-other-window-flag
	(select-window window))))

(defun caml-info-lookup-guess-id ()
  "Find a possible OCaml identifier near point."
  (save-excursion
    (let ((oldpoint (point)) 
	  start end)
      (skip-syntax-backward "w_.") 
      (setq start (point))
      (goto-char oldpoint)
      (skip-syntax-forward "w_.") 
      (setq end (point))
      (when (search-backward "#" start t)
	(setq start (point)))
      (buffer-substring-no-properties start end))))

(defun caml-info-lookup-id (id)
  "Lookup an OCaml identifier in a OCamldoc-generated info file."
  (interactive
   (let ((word (caml-info-lookup-guess-id)))
     (list (read-string
	    (format "id to lookup (%s): " word)
	    nil 'caml-info-lookup-history word))))
  (unless (assoc (buffer-name) caml-info-lookup-opened-modules)
    (caml-info-lookup-scan-open))
  (unless (assoc (buffer-name) caml-info-lookup-module-aliases)
    (caml-info-lookup-scan-aliases))
  (let (method)
    (when (= (aref id 0) ?#)
      (setq method t)
      (setq id (substring id 1)))
    (let* ((parts (nreverse (split-string id "\\.")))
	   (entry (car parts))
	   (modules (nreverse (cdr parts))))
      (if (and (null modules) (string-match "^[A-Z]" entry))
	  (setq modules (cons entry nil)))
      (caml-info-lookup entry modules method))))

(defun caml-info-lookup-scan-open ()
  "Looks for `open' directives in caml files"
  (let (modules id mlist)
    (save-excursion
      (goto-char (point-min))
      (let ((open-regexp "^[ \t]*open[ \t]+\\([A-Z_][a-zA-Z0-9_]*\\)"))
	(while (re-search-forward open-regexp nil t)
	  (unless (caml-in-comment-p)
	    (setq id (match-string-no-properties 1))
	    (setq modules (cons id modules))))))
    (setq mlist (assoc (buffer-name) caml-info-lookup-opened-modules))
    (if mlist
	(setcdr mlist modules)
      (setq caml-info-lookup-opened-modules
	    (cons (cons (buffer-name) modules) 
		  caml-info-lookup-opened-modules)))))

(defun caml-info-lookup-scan-aliases ()
  "Looks for modules aliases directives in caml files"
  (let (aliases id1 id2 mlist)
    (save-excursion
      (goto-char (point-min))
      (let ((module-regexp "^[ \t]*module[ \t]+\\([A-Z_][a-zA-Z0-9_]*\\)[ \t]+=[ \t]+\\([A-Z_][a-zA-Z0-9_]*\\(\\.[A-Z_][a-zA-Z0-9_]*\\)*\\)"))
	(while (re-search-forward module-regexp nil t)
	  (unless (caml-in-comment-p)
	    (setq id1 (match-string-no-properties 1))
	    (setq id2 (match-string-no-properties 2))
	    (when id2
	      (setq aliases 
		    (cons (cons id1 (split-string id2 "\\.")) aliases)))))))
    (setq mlist (assoc (buffer-name) caml-info-lookup-module-aliases))
    (if mlist
	(setcdr mlist aliases)
      (setq caml-info-lookup-module-aliases
	    (cons (cons (buffer-name) aliases) 
		  caml-info-lookup-module-aliases)))))


(eval-after-load "caml"
  '(progn
     (define-key caml-mode-map
       [?\C-c ?h] 'caml-info-lookup-id)
     (define-key caml-mode-map
       [?\C-c ?r] 'caml-info-lookup-rescan)))
(eval-after-load "inf-caml"
  '(progn 
     (define-key inferior-caml-mode-map
       [?\C-c ?h] 'caml-info-lookup-id)
     (define-key inferior-caml-mode-map
       [?\C-c ?r] 'caml-info-lookup-rescan)))
(add-hook 'inferior-caml-mode-hooks
	  '(lambda () (setq case-fold-search nil)))

(provide 'caml-info-look)
