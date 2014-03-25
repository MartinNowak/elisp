;;	$Id: vc-vss.el,v 1.12 2004/10/30 08:29:57 robert Exp robert $	
;;
;; Notes/Known Bugs
;; The .ini file is parsed but sometimes a file is incorrectly assumed to be under sourcesafe control
;; e.g.
;; $/Proj1/Dep1 -> /Proj/Dep
;; $/Proj -> /Proj
;; but if you have /Proj/Dep1 vc-vss decides that it any files in
;; /Proj/Dep whose names are in common with Proj1 then they are
;; considered to be under vss control and C-x C-q will check them
;; in/out!
;;
;; If you use the editor setting to view files under vss, you will need
;; to hand edit your ss.ini file inserting a line reading
;; Comment_Editor = 
;; otherwise your editor will startup containing a file
;; Enter a comment; then save and exit.
;; whenever you check something out!


;; How about shortcutting it all by checking for the existence of 
;; mssccprj.scc????
;; could even parse this file instead of vc-vss-path?

;; VC keeps some per-file information in the form of properties (see
;; vc-file-set/getprop in vc-hooks.el).  The backend-specific functions
;; do not generally need to be aware of these properties.  For example,
;; `vc-sys-workfile-version' should compute the workfile version and
;; return it; it should not look it up in the property, and it needn't
;; store it there either.  However, if a backend-specific function does
;; store a value in a property, that value takes precedence over any
;; value that the generic code might want to set (check for uses of 
;; the macro `with-vc-properties' in vc.el).
;;

;; May 2004 Fix bug when reverting a buffer - I was fooled by out of
;; date documentation on checkout
(eval-when-compile (require 'vc))
;; In the list of functions below, each identifier needs to be prepended
;; with `vc-sys-'.  Some of the functions are mandatory (marked with a
;; `*'), others are optional (`-').
;;
(defvar vc-vss-master-templates 'vc-find-vss)
;; STATE-QUERYING FUNCTIONS
;;
;; * registered (file)
;;
;;   Return non-nil if FILE is registered in this backend.
(defun vc-vss-registered (f)
    (let* (
	   (dirname (or (file-name-directory f) ""))
	   (basename (file-name-nondirectory f))
	   prj
	   )
      (setq prj (catch 'found (vc-find-vss dirname basename) nil))
      (if prj (vc-file-setprop f 'vc-name basename))
      prj))

(defvar vc-vss-not-in-vss nil
  "cache of files under VSS `folders', but not under VSS control")
(defvar vc-vss-path nil
  "*If non-nil, path where the <user>.INI file may be found for Visual SourceSafe")
(defvar vc-vss-open-async nil
  "*If non-nil, initially deem all files under VSS `folders' to be VSS
controlled, and spawn async job to correct as soon as possible.")
(defvar vc-vss-open-async-rw nil
  "*If non-nil, possibly allow writing a file while async VSS is happening.")
(defvar vc-vss-share-text t
  "*if non-nil, text files may be checked out by more than one user at a time,
within Visual SourceSafe.")
(defvar vc-vss-my-username nil
  "*If non-nil, string representing your username in VSS as you would see
in `ss status' as owning a lock (if nil, login name will be generally used)")
(defvar vc-vss-downcase-lockowner t
  "*If non-nil, make up for braindead code in VSS that screws with case.
you should probably have this be `t' and vc-vss-my-username nil (defaults) if
vss usernames are just login names, minus some problems with case.")
(defvar vc-vss-force-prj nil
  "If non-nil, VSS will set the current project based on the default-directory.
this variable gets determined by reading the ss.ini file.")
(defvar vc-vss-not-in-vss nil
  "cache of files under VSS `folders', but not under VSS control")
(defvar vc-vss-workbuffer " *vc-vss-workbuffer*")
(defvar vc-vss-dirs ()
  "static location of parsed SS.INI file")
(defvar vc-vss-dirs-mtime ()
  "mtime of SS.INI file when it was parsed")
(defvar vc-vss-user nil
  "*Username/password if needed and different from current user.  If a password is
  also required use the form Username,Password")
(defvar vc-trust-mssccprj t
  "If mssccprj.scc does not exist then the directory is not under source safe control
  should be reliable, unless we've never used the VSS i/f for the project?")
(defcustom vc-vss-diff-context 2 "Number of context lines in difference")
(defcustom vc-vss-use-diff nil "If nil use the vss diff otherwise assumes diff is installed")


(defun vc-vss-project (dirname)
  "return vss-style project name given dirname"
  (let ((ssdirs vc-vss-dirs)
	(case-fold-search t)
	rc prj-root d wf)
    (require 'cl)
    (setq dirname (expand-file-name dirname)) ; XXX necessary?
    (while (and (not rc) (setq d (pop ssdirs)))
      (setq rc (string-match
		(format "^%s" (setq wf (expand-file-name (car d))))
		dirname)))
    (setq prj-root (cdr d))
    (cond
     ((not rc)
      nil)
     ((string= wf dirname)
      prj-root)
     (t
      (concat prj-root "/" (file-relative-name dirname wf))))))

(defun vc-find-vss (dirname basename); fullname)
  "check if dirname/basename is handled by VSS (visual sourcesafe)"
  (cond
   (vc-vss-path
    (let ((prj (vc-vss-project dirname))
	  buffer errmsg attrs)
      (cond
       ((or prj (null vc-vss-dirs))
	(cond
	 ((null (setq attrs (file-attributes vc-vss-path)))
	  (setq errmsg (format "Cannot find vc-vss-path (%s); clear? "
			       vc-vss-path))
	  (cond
	   ((y-or-n-p errmsg)
	    (setq vc-vss-path nil))))
	 ((not (equal (nth 5 attrs) vc-vss-dirs-mtime))
	  (setq buffer (get-buffer-create vc-vss-workbuffer))
	  (save-excursion
	    (set-buffer buffer)
	    (erase-buffer)
	    (condition-case nil
		(insert-file-contents vc-vss-path nil nil nil t)
	      (error
	       (setq errmsg (format "Cannot read vc-vss-path (%s); clear? "
				    vc-vss-path))
	       (cond
		((y-or-n-p errmsg)
		 (setq vc-vss-path nil))))))
	  (cond
	   ((null errmsg)
	    (setq vc-vss-dirs (vc-vss-parse-ini buffer)
		  vc-vss-dirs-mtime (nth 5 attrs))))))
	(cond
	 ((bufferp buffer)
	  (kill-buffer buffer)))
	(cond
	 (vc-vss-path
	  (cond
	   ((null prj)
	    (setq prj (vc-vss-project dirname))))
	  (cond
	   ((or (null prj) (member (concat dirname basename); fullname
				   vc-vss-not-in-vss))
	    nil)
	   (vc-vss-open-async
	    (vc-vss-open-async dirname basename  prj) ; fullname
	    (throw 'found (cons prj 'VSS)))
	   ((vc-file-vss-controlled-p dirname basename  prj) ; fullname
	    (throw 'found (cons prj 'VSS))))))))))))

;;
;; * state (file) 
;;
;;   Return the current version control state of FILE.  For a list of
;;   possible values, see `vc-state'.  This function should do a full and
;;   reliable state computation; it is usually called immediately after
;;   C-x v v.  If you want to use a faster heuristic when visiting a
;;   file, put that into `state-heuristic' below.
;;
(defun vc-vss-state (file)
; textp is a flag we need to tell if the file is binary
;  (let ((project (vc-vss-project (file-name-directory file))) (textp nil))
;    (vc-do-command nil 1 "ss" (file-name-nondirectory file) "properties" "-I-"
;		   ;(concat "-P" project)
;		   (and textp vc-vss-share-text
;			"-U"))
;    (vc-vss-parse-status)))
;    (vc-file-getprop file 'vc-state)))
  (let ((file-owner nil)
	(ss-user-name nil)
	(vss-login (if vc-vss-user
			(concat "-Y" vc-vss-user) ""))
	(differs-to-master nil))
    ;;
    ;; Get required information; check out flag, edited flag and user name
    (with-temp-buffer
      (call-process "ss" nil t nil "cp" (vc-vss-project (file-name-directory file))
		    vss-login)
      (delete-region (point-min) (point-max))
      (call-process "ss" nil t nil "status" (file-name-nondirectory file)
		    vss-login)
      (goto-char (point-min))
      (if (re-search-forward "No checked out files found" (point-max) t)
	  (setq file-owner nil)
	(goto-char (point-min))
	;; SourceSafe 6.0 outputs the project in the form
	;; "$/project:".  If the first line looks like this, skip to
	;; the next line.
	(if (looking-at "^\\$") (forward-line))
	(setq file-owner (buffer-substring (+ (point) 20) (+ (point) 38)))
	(setq file-owner (substring file-owner 0 (string-match " " file-owner))))
      (delete-region (point-min) (point-max))
      (call-process "ss" nil t nil "diff" (file-name-nondirectory file)
		    vss-login)
      (goto-char (point-min))
      (if (re-search-forward "No differences" (point-max) t)
	  (setq differs-to-master nil)
	(setq differs-to-master t))
      (delete-region (point-min) (point-max))
      (call-process "ss" nil t nil "whoami" vss-login)
      (goto-char (point-min))
      (re-search-forward "^\\(.*\\)$" (point-max) nil)
      (setq ss-user-name (match-string 1)))
    (cond
     ; up to date, and not locked
     ((and (equal file-owner nil) (not differs-to-master))
      'up-to-date)
     ; up to date, but locked
     ((and (not differs-to-master) (not (string= file-owner ss-user-name)))
      file-owner)
     ; locked by user
     ((string= file-owner ss-user-name)
      'edited)
     ; locked by me, but differs, needs merge
     ((and (string= file-owner ss-user-name) differs-to-master)
      'needs-merge)
     ; differs to master
     ((and (not (string= file-owner ss-user-name)) differs-to-master)
      'needs-patch)
     (t
      (error "Some other state I've not yet determined...")))))
;  'up-to-date)

;; - state-heuristic (file)
;;
;;   If provided, this function is used to estimate the version control
;;   state of FILE at visiting time.  It should be considerably faster
;;   than the implementation of `state'.  For a list of possible values,
;;   see the doc string of `vc-state'.
;;
(defun vc-vss-state-heuristic (file)
  "VSS-specific state heuristic."
  (if (not (vc-mistrust-permissions file))
      ;;   This implementation assumes that any file which is under version
      ;; control and has -rw-r--r-- is locked by its owner.  
      (let* ((attributes (file-attributes file))
             (owner-uid  (nth 2 attributes))
             (permissions (nth 8 attributes)))
	(if (string-match ".r-..-..-." permissions)
            'up-to-date
          (if (string-match ".rw..-..-." permissions)
              (if (file-ownership-preserved-p file)
                  'edited
                (vc-user-login-name owner-uid))
          ;; Strange permissions.
          ;; Fall through to real state computation.
          (vc-vss-state file)))
    (vc-vss-state file))))

;; - dir-state (dir)
;;
;;   If provided, this function is used to find the version control state
;;   of all files in DIR in a fast way.  The function should not return
;;   anything, but rather store the files' states into the corresponding
;;   `vc-state' properties.

(defun vc-vss-dir-state (dir)
  (let (
	(vss-login (if vc-vss-user
		       (concat "-Y" vc-vss-user) "")))
	(with-temp-buffer
;      (call-process "ss" nil t nil "cp" (vc-vss-project (file-name-directory file))
;		    vss-login)
	  (vc-do-command nil 'async "ss" (vc-name dir) "cp" "-I-" vss-login)
	  )))

;;
;; * workfile-version (file)
;;
;;   Return the current workfile version of FILE.
(defun vc-vss-workfile-version (file)
  (with-temp-buffer
    (require 'vc)
    (vc-do-command t 1 "ss" 
		   (file-name-nondirectory file) ;file 
		   "properties" "-I-" (if vc-vss-user  (concat "-Y" vc-vss-user)))
    (vc-parse-buffer
     "^  Version: *\\([^ \t\n]+\\)" 1)))

;  (vc-workfile-version file))
;;
;; - latest-on-branch-p (file)
;;
;;   Return non-nil if the current workfile version of FILE is the latest
;;   on its branch.  The default implementation always returns t, which
;;   means that working with non-current versions is not supported by
;;   default.
;;
;; * checkout-model (file)
;;
;;   Indicate whether FILE needs to be "checked out" before it can be
;;   edited.  See `vc-checkout-model' for a list of possible values.
(defun vc-vss-checkout-model (file)
  'locking)
;;
;; - workfile-unchanged-p (file)
;;
;;   Return non-nil if FILE is unchanged from its current workfile
;;   version.  This function should do a brief comparison of FILE's
;;   contents with those of the master version.  If the backend does not
;;   have such a brief-comparison feature, the default implementation of
;;   this function can be used, which delegates to a full
;;   vc-BACKEND-diff.
;;
;; - mode-line-string (file)
;;
;;   If provided, this function should return the VC-specific mode line
;;   string for FILE.  The default implementation deals well with all
;;   states that `vc-state' can return.
;;
;; - dired-state-info (file)
;;
;;   Translate the `vc-state' property of FILE into a string that can be
;;   used in a vc-dired buffer.  The default implementation deals well
;;   with all states that `vc-state' can return.
;;
;; STATE-CHANGING FUNCTIONS
;;
;; * register (file &optional rev comment)
;;
;;   Register FILE in this backend.  Optionally, an initial revision REV
;;   and an initial description of the file, COMMENT, may be specified.
(defun vc-vss-register (file &optional rev comment)
  (vc-vss-stop-if-async file) ; this shouldn't happen...
  (setq vc-vss-not-in-vss (delete file vc-vss-not-in-vss))
  (vc-do-command nil 0 "ss" file  ;; VSS
		 "add" "-I-"
		 (or (and comment (string-match "[^\t\n ]" comment)
			  (concat "-C" comment))
		     "-C-") (if vc-vss-user  (concat "-Y" vc-vss-user))))
;;
;; - responsible-p (file)
;;
;;   Return non-nil if this backend considers itself "responsible" for
;;   FILE, which can also be a directory.  This function is used to find
;;   out what backend to use for registration of new files and for things
;;   like change log generation.  The default implementation always
;;   returns nil.
;;
;; - could-register (file)
;;
;;   Return non-nil if FILE could be registered under this backend.  The
;;   default implementation always returns t.
;;
;; - receive-file (file rev)
;;
;;   Let this backend "receive" a file that is already registered under
;;   another backend.  The default implementation simply calls `register'
;;   for FILE, but it can be overridden to do something more specific,
;;   e.g. keep revision numbers consistent or choose editing modes for
;;   FILE that resemble those of the other backend.
;;
;; - unregister (file)
;;
;;   Unregister FILE from this backend.  This is only needed if this
;;   backend may be used as a "more local" backend for temporary editing.
;;
;; * checkin (file rev comment)
;;
;;   Commit changes in FILE to this backend.  If REV is non-nil, that
;;   should become the new revision number.  COMMENT is used as a
;;   check-in comment.
;;
(defun vc-vss-checkin (file rev comment)
  (let ((switches (if (stringp vc-checkin-switches)
		      (list vc-checkin-switches)
		    vc-checkin-switches)))
  (vc-vss-stop-if-async file)
  (if rev (error "cannot specify rev for VSS checkin"))
  (vc-do-command nil 0 "ss" file 
	 "checkin" "-I-"
	 (concat "-C" comment)
	 (if vc-vss-user  (concat "-Y" vc-vss-user)))
	 switches))
;  (vc-file-setprop file 'vc-locking-user 'none)
;  (vc-file-setprop file 'vc-workfile-version nil))

;; * checkout (file &optional editable rev destfile)
;;
;;   Check out revision REV of FILE into the working area.  If EDITABLE
;;   is non-nil, FILE should be writable by the user and if locking is
;;   used for FILE, a lock should also be set.  If REV is non-nil, that
;;   is the revision to check out (default is current workfile version);
;;   If REV is t, that means to check out the head of the current branch;
;;   if REV is the empty string, that means to check out the head of the
;;   trunk.  If optional arg DESTFILE is given, it is an alternate
;;   filename to write the contents to.

(defun vc-vss-checkout (file &optional editable rev destfile)
  (let ((switches (if (stringp vc-checkout-switches)
		      (list vc-checkout-switches)
		    vc-checkout-switches)))
    (message "Checking out %s..." file)
    (if destfile
	;; Using "view" works ok so long as the file is registered in
	;; SourceSafe as a text file.
	(apply 'vc-do-command nil 0 "ss" file 
	       "view" "-I-"
	       (concat "-O" destfile)
	       (and rev (concat "-V" rev))
	       (if vc-vss-user (concat "-Y" vc-vss-user) "-Y") switches)
      (if editable
	  (apply 'vc-do-command nil 0 "ss" file 
		 "checkout" "-C" "-I-"
		 (and rev (concat "-V" rev))
		 (if vc-vss-user  (concat "-Y" vc-vss-user) "-Y") switches)
	(apply 'vc-do-command nil 0 "ss" file 
	       "get" "-GCC" "-I-" (if vc-vss-user  (concat "-Y" vc-vss-user) "-Y")
	       (and rev (stringp rev) (concat "-V" rev))
	       switches)
	)
      )
      (message "Checking out %s...done" file)))


;;
;; * revert (file)
;;
;;   Revert FILE back to the current workfile version.
;;
(defun vc-vss-revert (file &optional contents-done)
  "Revert FILE to the version it was based on."
  (if contents-done (message "N/A"))

  ;; SourceSafe 6.0 defaults to "No" for the replace, but can be
  ;; forced to revert with the -I-Y option.
  (vc-do-command nil 0 "ss" file  "undocheckout" "-I-Y" (if vc-vss-user  (concat "-Y" vc-vss-user) "-Y")
		 "-G"))
;; - cancel-version (file editable)
;;
;;   Cancel the current workfile version of FILE, i.e. remove it from the
;;   master.  EDITABLE non-nil means that FILE should be writable
;;   afterwards, and if locking is used for FILE, then a lock should also
;;   be set.  If this function is not provided, trying to cancel a
;;   version is caught as an error.
;;
;; - merge (file rev1 rev2)
;;
;;   Merge the changes between REV1 and REV2 into the current working file.
;;
;; - merge-news (file)
;;
;;   Merge recent changes from the current branch into FILE.
;;
;; - steal-lock (file &optional version)
;;
;;   Steal any lock on the current workfile version of FILE, or on
;;   VERSION if that is provided.  This function is only needed if
;;   locking is used for files under this backend, and if files can
;;   indeed be locked by other users.
;;
;; HISTORY FUNCTIONS
;;
;; * print-log (file)
;;
;;   Insert the revision log of FILE into the *vc* buffer.
;;
(defun vc-vss-print-log (file)
  "Get change log associated with FILE."
  ;; Note: (vc-name) is returning "$//ss/file/dir/path/" without the
  ;; base name (thus dumping the directory history, not the file
  ;; history).  This is probably an error setting "vc-name" attribute,
  ;; but (file-name-nondirectory) works just as well.

  ;;(vc-do-command nil 'async "ss" (vc-name file) "history" "-I-" 
  (vc-do-command nil 'async "ss" (file-name-nondirectory file) "history" "-I-"
		 (if vc-vss-user  (concat "-Y" vc-vss-user))))

;; - show-log-entry (version)
;;
;;   If provided, search the log entry for VERSION in the current buffer,
;;   and make sure it is displayed in the buffer's window.  The default
;;   implementation of this function works for RCS-style logs.
;;
;; - wash-log (file)
;;
;;   Remove all non-comment information from the output of print-log.  The
;;   default implementation of this function works for RCS-style logs.
;;
;; - logentry-check ()
;;
;;   If defined, this function is run to find out whether the user
;;   entered a valid log entry for check-in.  The log entry is in the
;;   current buffer, and if it is not a valid one, the function should
;;   throw an error.
;;
;; - comment-history (file)
;;
;;   Return a string containing all log entries that were made for FILE.
;;   This is used for transferring a file from one backend to another,
;;   retaining comment information.  The default implementation of this
;;   function does this by calling print-log and then wash-log, and
;;   returning the resulting buffer contents as a string.
;;
;; - update-changelog (files)
;;
;;   Using recent log entries, create ChangeLog entries for FILES, or for
;;   all files at or below the default-directory if FILES is nil.  The
;;   default implementation runs rcs2log, which handles RCS- and
;;   CVS-style logs.
;;
;; * diff (file &optional rev1 rev2)
;;
;;   Insert the diff for FILE into the *vc-diff* buffer.  If REV1 and REV2
;;   are non-nil, report differences from REV1 to REV2.  If REV1 is nil,
;;   use the current workfile version (as found in the repository) as the
;;   older version; if REV2 is nil, use the current workfile contents as
;;   the newer version.  This function should return a status of either 0
;;   (no differences found), or 1 (either non-empty diff or the diff is
;;   run asynchronously).
(defun vc-vss-diff (file &optional oldvers newvers)
      (let ((default-directory (file-name-directory file))
	    vstring status options)
	(if (not vc-vss-use-diff)
	    ;; Use ss to generate differences
	    (setq
	     vstring (cond
		      ((and oldvers newvers)
		       (format "-V%s~%s" newvers oldvers))
		      (oldvers ;; FIXME: unimplemented!
		       (format "-V%s" oldvers))
		      (t
		       nil))
	     options (append (if (listp diff-switches)
				 diff-switches
			       (list diff-switches)))
	     status (apply 'vc-do-command "*vc-diff*" 1 "ss" file
			   "diff" "-I-" vstring (if vc-vss-user  (concat "-Y" vc-vss-user))options))
	  ;; Use diff to generate differences.  More expensive,
	  ;; but more pleasant.
	  (let* (
		 (oldfilename (concat file ".~"
				      (or oldvers (vc-workfile-version file))
				      "~"))
		 (newfilename (if newvers
				  (concat file ".~" newvers "~")
				file))
		 )
	    (or (file-exists-p oldfilename)
		(vc-vss-checkout file nil oldvers
				 (file-name-nondirectory oldfilename)))
	    (or (not newvers)
		(file-exists-p newfilename)
		(vc-vss-checkout file nil newvers 
				 (file-name-nondirectory newfilename)))
	    (setq status
		  (apply 'vc-do-command
			 "*vc-diff*" 1 "diff" nil
			 (append (if (listp diff-switches) 
				     diff-switches
				   (list diff-switches))
				 (list oldfilename newfilename))))
	    ) ;; let
	  ) ;; if
	status))

;;
;; - annotate-command (file buf rev)
;;
;;   If this function is provided, it should produce an annotated version
;;   of FILE in BUF, relative to version REV.  This is currently only
;;   implemented for CVS, using the `cvs annotate' command.
;;
;; - annotate-difference (point)
;;
;;   Only required if `annotate-command' is defined for the backend.
;;   Return the difference between the age of the line at point and the
;;   current time.  Return NIL if there is no more comparison to be made
;;   in the buffer.  Return value as defined for `current-time'.  You can
;;   safely assume that point is placed at the beginning of each line,
;;   starting at `point-min'.  The buffer that point is placed in is the
;;   Annotate output, as defined by the relevant backend.
;;
;; SNAPSHOT SYSTEM
;;
;; - create-snapshot (dir name branchp)
;;
;;   Take a snapshot of the current state of files under DIR and name it
;;   NAME.  This should make sure that files are up-to-date before
;;   proceeding with the action.  DIR can also be a file and if BRANCHP
;;   is specified, NAME should be created as a branch and DIR should be
;;   checked out under this new branch.  The default implementation does
;;   not support branches but does a sanity check, a tree traversal and
;;   for each file calls `assign-name'.
;;
;; - assign-name (file name)
;;
;;   Give name NAME to the current version of FILE, assuming it is
;;   up-to-date.  Only used by the default version of `create-snapshot'.
;;
;; - retrieve-snapshot (dir name update)
;;
;;   Retrieve a named snapshot of all registered files at or below DIR.
;;   If UPDATE is non-nil, then update buffers of any files in the
;;   snapshot that are currently visited.  The default implementation
;;   does a sanity check whether there aren't any uncommitted changes at
;;   or below DIR, and then performs a tree walk, using the `checkout'
;;   function to retrieve the corresponding versions.
;;
;; MISCELLANEOUS
;;
;; - make-version-backups-p (file)
;;
;;   Return non-nil if unmodified repository versions of FILE should be
;;   backed up locally.  If this is done, VC can perform `diff' and
;;   `revert' operations itself, without calling the backend system.  The
;;   default implementation always returns nil.
;;
;; - check-headers ()
;;
;;   Return non-nil if the current buffer contains any version headers.
(defun vc-vss-check-headers ()
  "Check if the current file has any headers in it."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "\\$[A-Za-z\300-\326\330-\366\370-\377]+\
\\(: [\t -#%-\176\240-\377]*\\)?\\$" nil t)))

;;
;; - clear-headers ()
;;
;;   In the current buffer, reset all version headers to their unexpanded
;;   form.  This function should be provided if the state-querying code
;;   for this backend uses the version headers to determine the state of
;;   a file.  This function will then be called whenever VC changes the
;;   version control state in such a way that the headers would give
;;   wrong information.
;;
;; - rename-file (old new)
;;
;;   Rename file OLD to NEW, both in the working area and in the
;;   repository.  If this function is not provided, the command
;;   `vc-rename-file' will signal an error.

;; utility functions

(defun vc-file-vss-controlled-p (dirname basename  myprj) ; fullpath
  "Return project name (non-nil) if file is controlled by Visual SourceSafe.
Assumes global vc-vss-dirs is correct."
  (let ((default-directory dirname)
	(infokill (get-buffer "*vc-info*"))
	rc)
    (cond
     (infokill
      (kill-buffer infokill)))
    (if (and vc-trust-mssccprj
	     (not (or (file-exists-p (concat dirname "/mssccprj.scc"))
		       (file-exists-p (concat dirname "/vssver.scc")))))
	nil
      (cond
       ((not vc-vss-force-prj)
	(vc-do-command nil 200 "ss" myprj "cp" "-I-" (if vc-vss-user  (concat "-Y" vc-vss-user)))))
      (setq rc (vc-do-command "*vc-info*" 200 "ss" basename "properties" "-I-" 
			      (if vc-vss-user  (concat "-Y" vc-vss-user))))
      (cond
       ((zerop rc)
					;      (save-excursion
			 ;	(set-buffer (get-buffer "*vc-info*"))
;	(vc-file-setprop (concat dirname basename) 'vc-vss-cached-properties
 ;			 (buffer-substring (point-min) (point-max))))
	t)
       (t
	nil)))))

(defun vc-vss-parse-ini (buffer)
  "parse SS.INI file, contained in buffer."
  (let (rc project rawpath sysname)
    (save-excursion
      ;; Local patch, the Cygwin (system-name) may be lower case, and
      ;; it may make some attempt at qualification by returning
      ;; "<host>.<domain>".  SourceSafe just includes the <host>
      ;; portion in ss.ini.  dsainty/20040817
      ;;
      (setq sysname (upcase (system-name)))
      (if (string-match "\\..*$" sysname)
	  (setq sysname (replace-match "" t t sysname)))

      (set-buffer buffer)
      (goto-char (point-min))
      (while (re-search-forward "^#include \\(.*\\)$" nil t)
	  (insert-file-contents (match-string 1)))
      (goto-char (point-min))
      (cond
       ((re-search-forward "force_prj *= *\\([a-z]+\\)" nil t)
	(setq vc-vss-force-prj (string-match "yes" (match-string 1)))))
      
      (goto-char (point-min))
      (while (re-search-forward "^\\[\\(.*\\)\\]$" nil t)
	(setq project (match-string 1))
	(forward-line)
	(if (eolp) (forward-line))
	(while (looking-at "^Dir (\\(.*\\)) = \\(.*\\)$")
	  (cond
	   ((and (looking-at "^Dir (\\(.*\\)) = \\(.*\\)$")
		 (string= sysname (match-string 1)))
	    (setq rawpath (match-string 2))

	    ;; Local patch, correct the ss.ini directory names for
	    ;; operation under Cygwin.  dsainty/20040817
	    ;;
	    (if (eq system-type 'cygwin)
		(progn
		  (setq rawpath (replace-regexp-in-string "\\\\" "/" rawpath))
		  (if (string-match "^\\([a-zA-Z]\\):/" rawpath)
		      (setq rawpath (replace-match
				     (concat
				      "/cygdrive/"
				      (downcase (match-string 1 rawpath))
				      "/") t t rawpath)
			    ))
		  ))

	    (setq rc (cons (cons rawpath project) rc))))
	  (forward-line))))
    (sort rc 'vc-vss-dirs-compare)))

(defun vc-vss-count-project-depth (proj)
  (list-length (split-string proj "/")))
(defun vc-vss-dirs-compare (a b)
  "compare `working folders', so that `deepest' path is first"
  (> (vc-vss-count-project-depth (cdr a)) (vc-vss-count-project-depth(cdr b))))
(defvar vc-vss-filename nil
  "used locally in async opens to store full path of file being queried")
(defvar vc-vss-basename nil
  "used locally in async opens to store base name of file being queried")
(defun vc-vss-open-async (dir base  prj)
  "paste together initial properties as VSS-controlled, and spawn async
job to set the story straight."
  (vc-file-setprop (concat dir base) 'vc-vss-open-async prj)
  (let ((buffy (generate-new-buffer (format " *%s-vss-open*" base)))
	(win32-quote-process-args t)
	(w32-quote-process-args t)
	aproc)
    (save-excursion
      (set-buffer buffy)
      (make-local-variable 'vc-vss-filename)
      (setq vc-vss-filename (concat dir base))
      (make-local-variable 'vc-vss-basename)
      (setq vc-vss-basename base)
      (cond
       (dir
	(setq default-directory dir)))
      (cond
       (vc-vss-force-prj
	(setq aproc
	      (start-process "vc-vss-open-1" buffy "ss" "properties"
			     "-I-" base))
	(set-process-sentinel aproc 'vc-vss-sentinel-1))
       (t
	(setq aproc
	      (start-process "vc-vss-open-0" buffy "ss" "cp"
			     "-I-" prj))
	(set-process-sentinel aproc 'vc-vss-sentinel-0))))))
(defun vc-vss-stop-if-async (file)
  "throw an error, or otherwise thwart operation if we're doing an async
operation on a VSS file"
  (let ((backend (vc-backend file)))
    (cond
     ((and (eq backend 'VSS)
	   (vc-file-getprop file 'vc-vss-open-async))
      (error "Async operation in progress on %s" file)))))

(defun vc-vss-sentinel-0 (myproc myevent)
  "called when async job `ss cp' completes"
  (let ((pstatus (process-status myproc))
	(ecode (process-exit-status myproc))
	(buffy (process-buffer myproc))
	(win32-quote-process-args t)
	(w32-quote-process-args t)
	newproc)
    (save-excursion
      (set-buffer buffy)
      (cond
       ((and (eq pstatus 'exit) (zerop ecode) (buffer-name buffy))
	(erase-buffer)
	(setq newproc (start-process "vc-vss-open-1" buffy "ss" "properties"
				      "-I-" vc-vss-basename))
	(set-process-sentinel newproc 'vc-vss-sentinel-1))
       (t
	(vc-vss-drop-vss vc-vss-filename)
	(kill-buffer buffy))))))

(defun vc-vss-sentinel-1 (myproc myevent)
  "called when async job `ss properties' completes"
  (let ((pstatus (process-status myproc))
	(ecode (process-exit-status myproc))
	(buffy (process-buffer myproc))
	(win32-quote-process-args t)
	(w32-quote-process-args t)
	endarg newproc)
    (save-excursion
      (set-buffer buffy)
      (cond
       ((and (eq pstatus 'exit) (zerop ecode) (buffer-name buffy))
	(vc-file-setprop vc-vss-filename 'vc-vss-cached-properties
			 (buffer-substring (point-min) (point-max)))
	(goto-char (point-min))
	(setq endarg (list vc-vss-basename))
	(cond
	 ((and vc-vss-share-text
	       (re-search-forward "^Type: *\\([^ \t\n]+\\)" nil t)
	       (string-match "text" (match-string 1)))
	  (setq endarg (cons "-U" endarg))))
	(erase-buffer)
	(setq newproc (apply 'start-process "vc-vss-open-2" buffy "ss"
			     "status" "-I-" endarg))
	(set-process-sentinel newproc 'vc-vss-sentinel-2))
       (t
	(vc-vss-drop-vss vc-vss-filename)
	(kill-buffer buffy))))))

(defun vc-vss-sentinel-2 (myproc myevent)
  "called when async job `ss status' completes"
  (let ((pstatus (process-status myproc))
	(ecode (process-exit-status myproc))
	(buffy (process-buffer myproc))
	filename filebuf)
    (save-excursion
      (set-buffer buffy)
      (setq filename vc-vss-filename
	    filebuf (get-file-buffer filename))
      (cond
       ((and filebuf (eq pstatus 'exit) (<= ecode 1) (buffer-name buffy))
	(vc-file-setprop vc-vss-filename 'vc-vss-cached-status-exit ecode)
	(vc-file-setprop vc-vss-filename 'vc-vss-cached-status
			 (buffer-substring (point-min) (point-max)))
	(vc-file-setprop vc-vss-filename 'vc-name
			 (vc-file-getprop vc-vss-filename 'vc-vss-open-async))
	(vc-file-setprop vc-vss-filename 'vc-vss-open-async nil)
;	(vc-fetch-master-properties vc-vss-filename)
	(save-excursion
	  (set-buffer filebuf)
	  (cond
	   ((and (not vc-vss-open-async-rw)
		 (file-writable-p filename))
	    (setq buffer-read-only nil))) ; might get reset in vc-mode-line
	  (vc-mode-line filename)))
       (t
	(vc-vss-drop-vss vc-vss-filename))))
    (kill-buffer buffy)))

(defun vc-vss-drop-vss (file)
  "used by async open; drop all VSS association with this file"
  (let ((filebuf (get-file-buffer file)))
    (cond
     (filebuf
      (save-excursion
	(set-buffer filebuf)
	(setq vc-mode nil)
	(force-mode-line-update)
	(add-hook 'kill-buffer-hook 'vc-vss-kill-buffer-hook nil t)
	(setq vc-vss-not-in-vss (cons file vc-vss-not-in-vss))
	(vc-file-clearprops file)
	(vc-file-setprop file 'vc-backend nil)
	(vc-file-setprop file 'vc-name nil))))))

(defun vc-vss-kill-buffer-hook ()
  "called when a non-VSS buffer under a VSS directory is killed"
  (setq vc-vss-not-in-vss (delete buffer-file-name vc-vss-not-in-vss)))

(defun vc-vss-parse-status (&optional full)
  "Parse output of \"ss status\" command in the current buffer.
Set file properties accordingly.  Unless FULL is t, parse only
essential information."
  (set-buffer (get-buffer "*vc*"))
  (vc-parse-buffer
   "^  Version: *\\([^ \t\n]+\\)" 1)  
;     ("^Type: *\\([^ \t\n]+\\)" 1)
 ;    ("^Store only latest version: *\\([^ \t\n]+\\)" 1)) ; not used yet

  )

;; Use (setenv "SSDIR"... to change database
;;
(defun vc-vss-change-database (db &optional user)
  (interactive "fNew ss.ini file: \nMusername: ")
  (setq vc-vss-dirs nil)
  ;; check we're been passed a ss.ini file?
  (setq vc-vss-path db)
  (if user
      (setq vc-vss-user user)))

(provide 'vc-vss)
