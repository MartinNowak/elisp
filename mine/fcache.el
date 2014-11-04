;;; fcache.el --- File Attributes (Meta-Data) Cache.

;; Author: Per Nordlöw

;; TODO Convert make-variable-buffer-local to fcache-set/get-property especially in uproj.el
;; TODO Remove non-existent files using `fcache-exists-p' when iterating dcache contents.
;; TODO When package has matured to all needed features make functions inline using `defsubst'.
;; TODO In `dcache-of': Iterate `new-subs' and reuse those that have the same name as in `old-subs'.
;; TODO In `find-file-hook' and `after-save-hook' cache `major-mode' and `file-sha1sum' of (buffer-file-name) and `object-sha1sum'
;; TODO Use `file-modes' in tramp related stuff?
;; TODO What do we gain defining new classes for fcache and dcache vectors?
;; Note: (mtime-num (+ (* 65536 (car mtime)) (cadr mtime))) ;current mod-time as a number.
;; TODO : Merge with semanticdb:
;;       - mtime => lastmodtime
;;       - fsize => fsize
;;
;; Warning: For 64-bit Emacs ints integers are 61-bit so we can pack mtime into one integer.
;;
;; TODO Tag access time in `dcache-di-atime' in `dcache-of' using `float-time'.
;;       Then `do-on-idle' `maphash' move flush unused elements of dcache-gdir to disk using `print.*' to .emacs/fcache/.
;;
;; TODO `fcache-fi-deps' is a list of strings, that are, if found, resolved to fcaches themselves.
;; TODO Or use hash-table `fcache-fi-props' that maps "deps" to list of strings.
;; TODO Optionally use sha1 if (subrp (intern-soft "sha1")) as an fcache-member.

(require 'elk-test)
(require 'benchmarks)

(when (or (fboundp 'file-watch)
          (fboundp 'file-unwatch))
  (warn "TODO Support file-watch and file-unwatch in fcache.el!"))

(defun fcache-deps (fcache)
  "Get dependencies for FCACHE as a list of fcaches."
  (shell-command "gcc -c -MD -E myio.hpp > /dev/null")
  ;; (parse-in-auto-build "myio.d")
  )
;; TEST: Test-Driven: Kör C-c x på ~/justcxx/tests/t_qsort.cpp
;;

;;;###autoload
(defgroup dfcache nil
  "Directory/File Cache."
  :group 'tools)

;; ---------------------------------------------------------------------------

(define-hash-table-test 'string-hash 'string-equal 'sxhash)

(defun dcache-make-default ()
  (make-hash-table :size 1031           ;TODO Is this a good default value?
                   :test 'string-hash))

(defvar dcache-gdirs
  (dcache-make-default)
  "Hash table that maps global directory names to their caches."
  )

;; Use: (describe-hash-table 'dcache-gdirs)
;; Use: (describe-hash-table (gethash "/bin" dcache-gdirs))
;; Use: (describe-hash-table (gethash "~" dcache-gdirs))
;; Use: (describe-hash-table (gethash "~/justcxx" dcache-gdirs))
;; Use: (describe-hash-table (gethash "~/justcxx/CL" dcache-gdirs))
;; Use: (describe-hash-table (gethash (elsub "mine") dcache-gdirs))
;; Use: (describe-hash-table (gethash (elsub "mine/tscan-tests") dcache-gdirs))
;; Use: (describe-hash-table (gethash "/usr/bin" dcache-gdirs))
;; Use: (describe-hash-table (gethash "/bin" dcache-gdirs))

;; ---------------------------------------------------------------------------

(defconst dcache-di-fname 0)
(defconst dcache-di-ftype 1)
(defconst dcache-di-mtime 2)
(defconst dcache-di-fsize 3)
(defconst dcache-di-subs 4) ;Index to sub-files hash-table (relative filename is used as hash key)
(defconst dcache-di-iter 5)
(defun dcachep (x)
  "Return non-nil if X is a `dcache'."
  (and (vectorp x) (= 6 (length x))))
(defun dcache-make (fname ftype mtime fsize &optional subs iter)
  "Return empty fcache for directory.
MTIME is current modification time. FSIZE is current size."
  `[,fname ,ftype ,mtime ,fsize ,subs ,iter])

(defsubst dcache-fname (dcache) (aref dcache dcache-di-fname))
(defsubst dcache-ftype (dcache) (aref dcache dcache-di-ftype))
(defsubst dcache-mtime (dcache) (aref dcache dcache-di-mtime))
(defsubst dcache-fsize (dcache) (aref dcache dcache-di-fsize))

;; Use together with `dcache-subs-count' to iterate directories
(defsubst dcache-get-iter (dcache) (aref dcache dcache-di-iter))
(defsubst dcache-set-iter (dcache iter) (aset dcache dcache-di-iter iter))
(defun dcache-reset-iter (dcache) (dcache-set-iter dcache 0))
(defun dcache-inc-iter (dcache) (dcache-set-iter dcache (1+ (dcache-get-iter dcache))))

(defun dcache-equal (dcache-a dcache-b)
  "Return non-nil if DCACHE-A and DCACHE-B are equal."
  (and (equal (dcache-ftype dcache-a)
              (dcache-ftype dcache-b))
       (equal (dcache-mtime dcache-a)
              (dcache-mtime dcache-b))
       (equal (dcache-fsize dcache-a)
              (dcache-fsize dcache-b))))

(defun dcache-reset ()
  "Clear All Directory and File Caches."
  (interactive)
  (maphash
   (lambda (key value)
     (let ((subs-hash (aref value dcache-di-subs)))
       (when subs-hash
         (maphash (lambda (sub-key sub-value)
                    (when sub-value
                      (fcache-clear sub-value)))
                  subs-hash)
         (clrhash subs-hash)            ;clear hash-table
         ;; (message "Deleted subs-hash of %s" key)
         )))
   dcache-gdirs)
  (clrhash dcache-gdirs)
  (setq dcache-gdirs (dcache-make-default)))

(defsubst dcache-uniquify-path (dirname)
  "Standardize (hash table key) format of DIRNAME.
Needed for hash-table uniquify."
  (expand-file-name (directory-file-name dirname)))

;; Note: Currently not used!
(defun dcache-make-obselete (dcache &optional depth)
  "Tag DCACHE as updated (obselete) by an external change."
  (let ((subs-hash (aref dcache dcache-di-subs)))
    (when subs-hash
      (maphash 'fcache-elt-tag-check-updates subs-hash)
      (when nil
        (clrhash subs-hash)
        (aset dcache dcache-di-subs nil))
      )))

(defun dcache-delete (dirname)
  "Delete dcache of DIRNAME."
  (remhash dirname
           dcache-gdirs))

(defun dcache-put (dirname dcache)
  "Set dcache DCACHE of DIRNAME."
  (puthash dirname
           dcache
           dcache-gdirs))

(defun dcache-copy-cb (dcache newname)
  "Copy (Transfer) DCACHE to NEWNAME."
  (let ((newname (dcache-uniquify-path newname)))
    (dcache-put newname (dcache-make newname
                                     (dcache-ftype dcache)
                                     (dcache-mtime dcache)
                                     (dcache-fsize dcache)))))

(defun dcache-move-cb (dcache file newname)
  "Move (Transfer) DCACHE from FILE to NEWNAME."
  (let ((file (dcache-uniquify-path file))
        (newname (dcache-uniquify-path newname)))
    (dcache-put newname dcache)
    (aset dcache dcache-di-fname newname)
    (dcache-delete file)))

(defun fcache-copy-cb (fcache file newname)
  "Copy (Transfer) FCACHE from FILE to NEWNAME."
  ;; (fcache-put newname fcache)
  ;; (aset fcache dcache-di-fname newname)
  )

(defun fcache-move-cb (fcache file newname)
  "Move (Transfer) FCACHE from FILE to NEWNAME."
  ;; (fcache-put newname fcache)
  ;; (aset fcache dcache-di-fname newname)
  ;; (fcache-delete file)
  )

(defun dcache-of (dirname &optional cached-only noerror)
  "Get directory cache associated with DIRNAME.
If CACHED-ONLY is non-nil don't check for file-system updates."
  (let* ((dirname (dcache-uniquify-path dirname))
         (dcache (gethash dirname dcache-gdirs)))
    (if cached-only
        dcache
      (if (file-directory-p dirname)
          (let* ((fattrs (file-attributes dirname))
                 (mtime (float-time (nth 5 fattrs)))
                 (ftype (nth 0 fattrs))
                 (fsize (nth 7 fattrs)))
            (if dcache
                (let ((obselete (not (and (<= mtime (aref dcache dcache-di-mtime))
                                          (eq fsize (aref dcache dcache-di-fsize))))))
                  ;; NOTE: directories have size information but it grows more
                  ;; slowly coarse-grained in multiples of 4096 on ext3
                  (when obselete        ;needs update
                    (let* ((old-subs (aref dcache dcache-di-subs)))
                      (aset dcache dcache-di-ftype ftype) ;update ftype
                      (aset dcache dcache-di-mtime mtime) ;update time
                      (aset dcache dcache-di-fsize fsize) ;update size
                      (aset dcache dcache-di-subs (dcache-directory-files-hash-table dcache nil old-subs))
                      (when old-subs (clrhash old-subs)) ;clear old hash-table after its been used
                      ;;(puthash dirname (dcache-make dirname ftype mtime fsize) dcache-gdirs)
                      ))
                  dcache)
              (puthash dirname (dcache-make dirname ftype mtime fsize) dcache-gdirs) ;dcache has not been defined so add it add new
              ))
        (unless noerror
          (error "%s not a directory!" dirname))))))

;; ---------------------------------------------------------------------------

(defconst fcache-fi-parent 0)
(defconst fcache-fi-fname 1)
(defconst fcache-fi-ftype 2)
(defconst fcache-fi-mtime 3)
(defconst fcache-fi-fsize 4)
(defconst fcache-fi-readable 5)
(defconst fcache-fi-writable 6)
(defconst fcache-fi-scans 7)
(defconst fcache-fi-types 8)
(defconst fcache-fi-props 9)
(defconst fcache-fi-tags 10)
(defconst fcache-fi-ops 11)

(defun fcachep (x)
  "Return non-nil if X is a `fcache'."
  (vectorp x))

(defsubst fcache-fname (fcache)
  "Get filename of FCACHE."
  (aref fcache fcache-fi-fname))

(defsubst fcache-full-fname (fcache)
  "Get full filename of FCACHE."
  (expand-file-name
   (aref fcache fcache-fi-fname)
   (dcache-fname (fcache-parent-dcache fcache))))

(defsubst fcache-parent-dcache (fcache)
  "Get parent filename of FCACHE."
  (aref fcache fcache-fi-parent))

;; ---------------------------------------------------------------------------

(defsubst fcache-timestamp (fcache)
  "Get timestamp (file content id, state hash) of FCACHE."
  (cons (aref fcache fcache-fi-mtime)
        (aref fcache fcache-fi-fsize)))

(defsubst fcache-get-scans (fcache)
  "Get scans of FCACHE."
  (aref fcache fcache-fi-scans))
(defsubst fcache-set-scans (fcache scans)
  "Set scans of FCACHE to SCANS."
  (aset fcache fcache-fi-scans scans))

(defsubst fcache-get-types (fcache)
  "Get types of FCACHE."
  (aref fcache fcache-fi-types))
(defsubst fcache-set-types (fcache types)
  "Set types of FCACHE to TYPES."
  (aset fcache fcache-fi-types types))

(defsubst fcache-register-op (fcache op-symbol args)
  "Get Operations of FCACHE."
  (aref fcache fcache-fi-ops))

;; ---------------------------------------------------------------------------

(defsubst fcache-get-tags (fcache)
  (aref fcache fcache-fi-tags))

(defsubst fcache-set-tags (fcache tags)
  (aset fcache fcache-fi-tags tags))

(defun fcache-set-tag (fcache tag value)
  "Set tag TAG of FCACHE to VALUE."
  (let ((plist (aref fcache fcache-fi-tags)))
    (aset fcache fcache-fi-tags
          (if plist
              (plist-put plist tag value)
            `(,tag ,value)))
    value))
;; Use: (fcache-set-tag (fcache-of "/bin/ls") :dummy "dummy-value")
;; Use: (fcache-get-tags (fcache-of "/bin/ls"))
;; Use: (fcache-get-tag (fcache-of "/bin/ls") :dummy)
;; Use: (fcache-of "/bin/ls")
;; Use: (fcache-get-tags (fcache-of (expand-file-name "/bin/ls")))

(defsubst fcache-get-tag (fcache tag)
  "Get tag TAG of FCACHE, defaulting to nil if not present."
  (plist-get (aref fcache fcache-fi-tags) tag))

(defun fcache-add-to-history-tag (fcache tag value)
  "Add VALUE to history tag TAG of FCACHE."
  (let ((history (fcache-get-tag fcache tag)))
    (fcache-set-tag fcache tag
                         (add-to-history 'history value))))
;;; (fcache-add-to-history-tag (fcache-of "/etc") :build-root "/")
;;; (fcache-add-to-history-tag (fcache-of "/etc") :build-dir "/etc")
;;; (fcache-get-tag (fcache-of "/etc") :build-root)
;;; (fcache-get-tag (fcache-of "/etc") :build-dir)
;;; (fcache-get-tags (fcache-of "/etc"))

;;; (fcache-add-to-history-tag (fcache-of "/etc") :build-type "Release")
;;; (fcache-add-to-history-tag (fcache-of "/etc") :build-type "Debug")
;;; (fcache-get-tag (fcache-of "/etc") :build-dir)

;; ---------------------------------------------------------------------------

(defsubst fcache-get-properties (fcache)
  (aref fcache fcache-fi-props))
(defalias 'fcache-get-attributes 'fcache-get-properties)

(defsubst fcache-set-properties (fcache props)
  (aset fcache fcache-fi-props props))
(defalias 'fcache-set-attributes 'fcache-set-properties)

(defun fcache-set-property (fcache prop value)
  "Set property PROP of FCACHE to VALUE."
  (let ((plist (aref fcache fcache-fi-props)))
    (aset fcache fcache-fi-props
          (if plist
              (plist-put plist prop value)
            `(,prop ,value)))
    value))
(defalias 'fcache-set-attribute 'fcache-set-property)
;; Use: (fcache-set-property (fcache-of "/bin/ls") :dummy "dummy-value")
;; Use: (fcache-get-properties (fcache-of "/bin/ls"))
;; Use: (fcache-get-property (fcache-of "/bin/ls") :dummy)
;; Use: (fcache-of "/bin/ls")
;; Use: (fcache-get-properties (fcache-of (expand-file-name "/bin/ls")))

(defsubst fcache-get-property (fcache prop)
  "Get property PROP of FCACHE, defaulting to nil if not present."
  (plist-get (aref fcache fcache-fi-props) prop))
(defalias 'fcache-get-attribute 'fcache-get-property)

(defun fcache-add-to-history-property (fcache prop value)
  "Add VALUE to history property PROP of FCACHE."
  (let ((history (fcache-get-property fcache prop)))
    (fcache-set-property fcache prop
                         (add-to-history 'history value))))
;;; (fcache-add-to-history-property (fcache-of "/etc") :build-root "/")
;;; (fcache-add-to-history-property (fcache-of "/etc") :build-dir "/etc")
;;; (fcache-get-property (fcache-of "/etc") :build-root)
;;; (fcache-get-property (fcache-of "/etc") :build-dir)
;;; (fcache-get-properties (fcache-of "/etc"))

;;; (fcache-add-to-history-property (fcache-of "/etc") :build-type "Release")
;;; (fcache-add-to-history-property (fcache-of "/etc") :build-type "Debug")
;;; (fcache-get-property (fcache-of "/etc") :build-dir)

;; ---------------------------------------------------------------------------

(defun fcache-vc-state-cached (fcache)
  "Return cached vc-state of `FCACHE'."
  (fcache-get-property fcache :vc-state))
;; (fcache-vc-state-cached (fcache-of (elsub "mine/dotemacs.elc")))

;; ---------------------------------------------------------------------------

(defun shell-command-scan-regexp (regexp &optional filename)
  (with-temp-buffer
    (let ((fn (expand-file-name (or filename
                                    buffer-file-name))))
      (shell-command (concat "make -pn"
                             " -C " (file-name-directory fn)
                             " -f " fn)
                     (current-buffer)))
    (goto-char (point-min))
    (let (tgts)
      (while (re-search-forward regexp nil t)
        (push (match-string 1) tgts))
      tgts)))

;; ---------------------------------------------------------------------------

(defun fcache-ftype (fcache)
  "Return file type of FCACHE.
Type can be either
- nil (regular)
- t (directory),
- string (unfollowed symlink)
- vector (followed symlink to target fcache).
Doesn't follow symbolic links."
  (aref fcache fcache-fi-ftype))
;; Use: (fcache-ftype (fcache-of (elsub "mine/tscan-tests/link/ls.copy")))
;; Use: (fcache-ftype (fcache-of (elsub "mine/tscan-tests/link/ls.alink")))
;; Use: (dcache-of (elsub "mine/tscan-tests/link"))
;; Use: (fcache-follow-link (fcache-of (elsub "mine/tscan-tests/link/ls.alink")))
;; Use: (fcache-follow-link (fcache-of (elsub "mine/tscan-tests/link/ls.rlink")))
;; Use: (fcache-chase-links (fcache-of (elsub "mine/tscan-tests/link/ls.alink")))
;; Use: (fcache-chase-links (fcache-of (elsub "mine/tscan-tests/link/ls.rlink")))

;; Use: (dcache-of (elsub "mine/tscan-tests/dirlink"))

(defun fcache-exists-p (fcache)
  "Return non-nil if FCACHE exists."
  (file-exists-p (fcache-full-fname fcache)))

(defun fcache-regular-p (fcache)
  "Return non-nil if FCACHE is a regular file."
  (null (fcache-ftype fcache)))

(defun fcache-directory-p (fcache)
  "Return non-nil if FCACHE is a directory."
  (eq t (fcache-ftype fcache)))

(defun fcache-symlink-p (fcache)
  "Return non-nil if FCACHE is a symbolic link, followed or not."
  (arrayp (fcache-ftype fcache)))       ;(or (stringp ftype) (vectorp ftype))

(defun fcache-unfollowed-symlink-p (fcache)
  "Return non-nil if FCACHE is an unfollowed symbolic link."
  (stringp (fcache-ftype fcache)))

(defun fcache-followed-symlink-p (fcache)
  "Return non-nil if FCACHE is a followed symbolic link."
  (vectorp (fcache-ftype fcache)))

(defun fcache-follow-relink (fcache)
  "Return symlink target of FCACHE.
If FCACHE is not a symbolic link return FCACHE.
Modifies internal cache structure."
  (let ((ftype (fcache-ftype fcache)))
    (if (stringp ftype)                 ;if type is symlink target
        (aset fcache fcache-fi-ftype
              (if (file-name-absolute-p ftype)
                  (fcache-of ftype) ;absolute name
                (dcache-rget-fcache ftype ;relative name
                                    (fcache-parent-dcache fcache))))
      fcache)))

(defun fcache-follow-link (fcache &optional noerror)
  "Return symlink target fcache of FCACHE.
If FCACHE is not a symbolic link return FCACHE.
Return nil if link target does not exist."
  (let ((ftype (fcache-ftype fcache)))
    (if (stringp ftype)                 ;if type is symlink target
        (if (file-name-absolute-p ftype)
            (fcache-of ftype nil noerror) ;absolute name
          (dcache-rget-fcache ftype       ;relative name
                              (fcache-parent-dcache fcache) nil noerror))
      fcache)))

(defun fcache-chase-links (fcache &optional relink)
  "Like `file-chase-links' but for FCACHE.
Returns last destination fcache.  Modifies internal cache
structure if RELINK is non-nil."
  ;; Note: Warning: If we used `file-chase-links' directly here we wouldn't
  ;; detect obselete links in chain.
  (while (fcache-unfollowed-symlink-p fcache)
    (setq fcache (if relink
                     (fcache-follow-relink fcache)
                   (fcache-follow-link fcache))))
  fcache)
;; Use: (fcache-chase-links (fcache-of (elsub "mine/tscan-tests/dirlink/sub.rlink")))
;; Use: (fcache-chase-links (fcache-of (elsub "mine/tscan-tests/dirlink/sub.rlink")) t)
;; Test: (progn (dcache-reset) (fcache-chase-links (fcache-of "/etc/rc3.d")))
;; Test: (progn (dcache-reset) (eq (fcache-chase-links (fcache-of "/etc/rc3.d/S75sudo")) (fcache-chase-links (fcache-of "/etc/init.d/sudo")))) => t

(defun fcache-chased-regular-p (fcache)
  "Return non-nil if FCACHE is a potentially chased regular file."
  (or (null (fcache-ftype fcache))
      (null (fcache-ftype (fcache-chase-links fcache)))))

;; ---------------------------------------------------------------------------

;; (defun fcache-rtime (fcache)
;;   "Return read timestamp of FCACHE.
;; Format is a floating point number."
;;   (aref fcache fcache-fi-rtime))
;; ;; Use: (fcache-rtime (fcache-of "/bin/ls"))

(defsubst fcache-mtime (fcache)
  "Return file modification time of FCACHE.
Format is a floating point number."
  (aref fcache fcache-fi-mtime))
;; Use: (fcache-mtime (fcache-of "/bin/ls"))

(defsubst fcache-fsize (fcache)
  "Return file size of FCACHE.
Format is either integer or floating point number."
  (aref fcache fcache-fi-fsize))
;; Use: (fcache-fsize (fcache-of "/bin/ls"))

(defsubst fcache-readable (fcache)
  "Return non-nil if FCACHE is readable."
  (aref fcache fcache-fi-readable))

(defsubst fcache-writable (fcache)
  "Return non-nil if FCACHE is writable."
  (aref fcache fcache-fi-writable))

(defun fcache-make (dcache fname ftype mtime fsize readable writable &optional scans types attrs tags ops old-fcache)
  "Return empty fcache for file.
MTIME is current modification time. FSIZE is current size."
  ;; (message "fcache-make: dcache:%s fname:%s" (dcache-fname dcache) fname)
  (let ((fcache `[,dcache ,fname ,ftype ,mtime ,fsize ,readable ,writable ,scans ,types ,attrs ,tags ,ops]))
    (when (and old-fcache (eq ftype t)) ;when previously cached directory
      (let ((props (fcache-get-properties old-fcache))) ;reuse its properties
        (when props
          (fcache-set-properties fcache props))))
    fcache))

(defun fcache-clear (fcache)
  "Return FCACHE clear (emptied)."
  (aset fcache fcache-fi-parent nil)    ;empty parent
  (aset fcache fcache-fi-scans nil)     ;empty scans
  (aset fcache fcache-fi-types nil)     ;empty types
  (aset fcache fcache-fi-props nil)     ;empty attributes
  (aset fcache fcache-fi-ops nil)       ;empty operations
  fcache)

(defun fcache-equal (fcache-a fcache-b &optional keep-time)
  "Return non-nil if FCACHE-A and FCACHE-B are equal."
  (and (equal (fcache-ftype fcache-a)
              (fcache-ftype fcache-b))
       (or (not keep-time)
           (equal (fcache-mtime fcache-a)
                  (fcache-mtime fcache-b)))
       (equal (fcache-fsize fcache-a)
              (fcache-fsize fcache-b))))

;; ---------------------------------------------------------------------------

(defun dcache-directory-files-hash-table (dcache &optional match old-subs)
  "Create a hash table for all files directly under directory DIRNAME.
If MATCH is non-nil, mention only file names that match the regexp MATCH."
  (let* ((dirname (dcache-fname dcache))
         (rtime (float-time))           ;read time(stamp) for `directory-files'
         (subs (directory-files dirname nil (or match directory-files-no-dot-files-regexp) t))
         (hash (make-hash-table
                :size (length subs)
                :test 'string-hash)))
    ;; add `subs' to `hash'
    (mapc (lambda (sub)
            (let* ((filename (expand-file-name sub dirname)) ;full filename
                   (fattrs (file-attributes filename))
                   (mtime (float-time (nth 5 fattrs)))
                   (fsize (nth 7 fattrs)))
              (let ((old-sub (when old-subs
                               (gethash sub old-subs))))
                (puthash sub
                         (if (and old-sub          ;if old sub is defined and
                                  (<= mtime rtime) ;file has not been modified
                                  (<= mtime (fcache-mtime old-sub)) ;and has same modification time
                                  (= fsize (fcache-fsize old-sub))) ;and file size
                             old-sub                                ;reuse it
                           (let ((rtime (float-time)) ;read time(stamp) for `file-attributes'
                                 (tags (when old-sub ;if tags
                                         (fcache-get-tags old-sub))) ;reuse them
                                 (ftype (nth 0 fattrs))) ;file type
                             (let ((new-sub (fcache-make dcache sub ftype
                                                         mtime fsize
                                                         (file-readable-p filename)
                                                         (file-writable-p filename)
                                                         nil nil nil tags nil old-sub)))
                               new-sub)))
                         hash)
                )
              ))
          subs)
    hash))

(defun dcache-subs (dcache &optional match)
  "Get (and if needed create) subs of DCACHE as a hash table."
  (or (aref dcache dcache-di-subs)
      (aset dcache dcache-di-subs      ;or create it
            (dcache-directory-files-hash-table dcache match))))
(defun dcache-subs-count (dcache &optional match)
  "Return number of sub-files/directories contained in DCACHE."
  (hash-table-count (dcache-subs dcache match)))

(defun fcache-dir-subs (dirname &optional match cached-only)
  "Get subs in directory DIRNAME as hash table.
If CACHED-ONLY is non-nil don't check for file-system updates."
  (dcache-subs (dcache-of dirname cached-only) match))
;; Use: (describe-hash-table (fcache-dir-subs "/bin"))
;; Use: (describe-hash-table (fcache-dir-subs "/usr/bin"))
;; Use: (fcache-dir-subs (elsub "mine/tscan-tests"))
;; Use: (fcache-dir-files (elsub "mine/tscan-tests/empty-gz/"))

(defun dcache-contains-file (dcache file)
  (gethash file (dcache-subs dcache)))
(eval-when-compile (when (file-exists-p "/bin/ls")
                     (assert-equal "ls" (fcache-fname (dcache-contains-file (dcache-of "/bin") "ls")))))
(defun directory-has-file-cached (directory file)
  (dcache-contains-file (dcache-of directory) file))
(eval-when-compile (when (file-exists-p "/bin/ls")
                     (assert-equal "ls" (fcache-fname (directory-has-file-cached "/bin" "ls")))))

(defun dcache-contains-files (dcache files)
  (delete nil (mapcar (lambda (filename) (dcache-contains-file dcache filename)) files)))
(defun directory-has-files-cached (directory files)
  (dcache-contains-files (dcache-of directory) files))

(defun dcache-dir-subs-fsize-sum (dcache &optional recurse)
  "Calculate file size sum of dcache's subs as floating point number.
If RECURSE is non-nil calculate recursive tree size of DCACHE."
  (let ((subs (dcache-subs dcache))
        (fsizes (float 0))               ;file size sum
        (subs-fsize (float 0))          ;directory sub-files sum
        )
    (maphash
     (lambda (key value)
       (setq fsizes (+ fsizes
                       (fcache-fsize value)))
       (when (and recurse  ;enter
                  (fcache-directory-p value) ;sub-directories
                  (fcache-readable value))
         ;;(message "Recursing into %s" (faze (fcache-full-fname value) 'file))
         (setq subs-fsize (+ subs-fsize (dcache-dir-subs-fsize-sum
                                         (dcache-of (fcache-full-fname value)) ;TODO Optimize?
                                         t)))))
     subs)
    ;; TODO Store `fsizes' in `dcache' and use at top of
    ;; `dcache-dir-subs-fsize-sum'?
    (if (eq recurse 'separate)
        (cons fsizes subs-fsize)
      (+ fsizes subs-fsize))))
;; Use: (dcache-dir-subs-fsize-sum (dcache-of "/etc/cups") 'separate)
;; Use: (dcache-dir-subs-fsize-sum (dcache-of (elsub "mine/tscan-tests")))
;; Use: (dcache-dir-subs-fsize-sum (dcache-of (elsub "mine/tscan-tests")) t)
;; Use: (dcache-dir-subs-fsize-sum (dcache-of (elsub "mine/tscan-tests")) 'separate)
;; Use: (dcache-dir-subs-fsize-sum (dcache-of "/usr/lib"))
;; Use: (dcache-dir-subs-fsize-sum (dcache-of "/usr/lib") t)
;; Use: (dcache-dir-subs-fsize-sum (dcache-of "/usr/lib") 'separate)

;; ---------------------------------------------------------------------------

(defun dcache-rget-fcache (relname dcache &optional cached-only noerror)
  "Get file cache of relative filename RELNAME in DCACHE."
  (let* ((subs (dcache-subs dcache nil))
         (dirname (dcache-fname dcache))
         (filename (expand-file-name relname dirname))
         (rtime (float-time))           ;read time(stamp) for `file-attributes'
         (old-sub (gethash relname subs)))
    (if cached-only                     ;if cached only
        old-sub                         ;just return cache (present or not)
      (let ((fattrs (file-attributes filename)))
        (if fattrs                      ;when file could be opened
            (let* ((mtime (float-time (nth 5 fattrs)))
                   (ftype (nth 0 fattrs))
                   (fsize (nth 7 fattrs)))
              (if (and old-sub          ;if either no cache (yet) or
                       (<= mtime rtime) ;file has not been modified
                       (<= mtime (fcache-mtime old-sub)) ;and has same modification time
                       (= fsize (fcache-fsize old-sub))  ;cache is unchanged
                       )
                  old-sub
                (puthash relname
                         (let ((tags (when old-sub ;if tags
                                       (fcache-get-tags old-sub)))) ;reuse them
                           (fcache-make dcache relname ftype mtime fsize ;create new fcache
                                        (file-readable-p filename)
                                        (file-writable-p filename)
                                        nil nil nil tags nil old-sub))
                         subs)          ;relate it to dcache subs
                ))
          (unless noerror
            (error "File %s does not exist" filename)))))))

(defun fcache-rget (relname dirname &optional cached-only noerror)
  "Get file cache of relative filename RELNAME in directory DIRNAME.
If NOERROR is non-nil return nil if file RELNAME could not be
found in directory DIRNAME, otherwise error."
  (let ((dcache (dcache-of dirname cached-only noerror)))
    (when dcache
      (dcache-rget-fcache relname dcache cached-only noerror))))

(defun fcache-of (filename &optional cached-only noerror)
  "Get file cache of FILENAME.
If NOERROR is non-nil return nil if file RELNAME could not be
found in directory DIRNAME, otherwise error."
  (let ((filename (dcache-uniquify-path filename)))
    (fcache-rget (file-name-nondirectory filename) ;relative filename
                 (file-name-directory filename)
                 cached-only             ;directory containing filename
                 noerror)))

;; ---------------------------------------------------------------------------

(defun file-timestamp (filename)
  (let* ((fattrs (file-attributes filename))
         (mtime (float-time (nth 5 fattrs)))
         (fsize (nth 7 fattrs)))
    (cons mtime fsize)))
(eval-when-compile (when (file-exists-p "/etc/passwd")
                     (assert-equal (file-timestamp "/etc/passwd")
                                   (fcache-timestamp (fcache-of "/etc/passwd")))))

(defun fcache-or-file-timestamp (fcache filename)
  (if fcache
      (fcache-timestamp fcache)
    (file-timestamp filename)))
;; Use: (fcache-or-file-timestamp (fcache-of "/etc/passwd") "/etc/passwd")

(defsubst fcache-or-file-fsize (fcache filename)
  (if fcache
      (fcache-fsize fcache)
    (file-size filename)))

;; ---------------------------------------------------------------------------

;; TODO Add caching!
(defun fcache-dir-files (dirname &optional full match cached-only)
  "Get subs in directory DIRNAME as a list.
If MATCH is non-nil, get only file names that match the regexp MATCH."
  (let ((subs))
    (maphash
     (lambda (key value)
       (when (or (not match)            ;either no matcher
                 (string-match match key)) ;or match
         (when full
           ;; TODO concat is much faster than `expand-file-name'. Check that
           ;; this works for a remote (TRAMP) `dirname' aswell.
           (setq key (concat dirname "/" key)))
         (if subs
             (nconc subs (list key))    ;append hit
           (setq subs (list key)))))
     (fcache-dir-subs dirname nil cached-only)) ;use cached only!
    subs))
(eval-when-compile (when (file-exists-p "/bin/grep")
                     (assert-equal (sort (fcache-dir-files "/bin" t "grep") 'string-lessp)
                                   (sort (directory-files "/bin" t "grep") 'string-lessp))))

;; ---------------------------------------------------------------------------

(defun dfcache-get (filename &optional cached-only noerror)
  "Return Directory Cache of FILENAME if a directory, otherwise return its File Cache."
  (if (file-directory-p filename)
      (dcache-of filename cached-only noerror)
    (fcache-of filename cached-only noerror)))

(defadvice copy-file (around fcache-copy-file (file newname
                                               &optional ok-if-already-exists keep-time preserve-uid-gid preserve-selinux-context) activate)
  "Copy dcache and fcache from FILE to NEWNAME."
  ad-do-it
  ;; TODO Handle case when newname is a directory.
  (let ((fcache (fcache-of file t)))
    (when fcache
      (fcache-copy-cb fcache file newname))))

(when nil                               ;TODO This fails on other host
  (let* ((wdir "/tmp")                  ;working directory
         (f1 "A")
         (f2 "B")
         (p1 (expand-file-name f1 wdir))
         (p2 (expand-file-name f2 wdir))
         (keep-time nil))
    (progn (cond ((file-regular-p p1) (delete-file p1))
                 ((file-directory-p p1) (delete-directory p1)))
           (cond ((file-regular-p p2) (delete-file p2))
                 ((file-directory-p p2) (delete-directory p2)))
           (with-temp-file p1)
           (dcache-reset)
           (and
            ;; absolute name test
            (let ((c1 (fcache-of p1)))
              (copy-file p1 p2)
              (let ((c2 (fcache-of p2 t)))
                (and (fcachep c2)
                     (fcache-equal c1 c2 keep-time)))) ;old fcache should be equal to new fcache (except filename)
            ;; undo using relative name test
            (let ((default-directory wdir))
              (let ((c2 (fcache-of f2)))
                (copy-file f2 f1 t)
                (let ((c1 (fcache-of f1 t)))
                  (and (fcachep c1)
                       (fcache-equal c2 c1 keep-time))) ;old fcache should be equal to new fcache (except filename)
                ))
            ))))

;; (defadvice copy-directory (around fcache-copy-directory (directory newname &optional keep-time parents copy-contents-time) activate)
;;   "Copy dcache and fcache from DIRECTORY to NEWNAME."
;;   (message "OK")
;;   ad-do-it                             ;do it
;;   (let ((dcache (dcache-of directory t)))
;;     (when dcache
;;       (dcache-copy-cb dcache newname))))
;; (eval-when-compile
;;   (assert-t
;;    (let* ((wdir "/tmp")                ;working directory
;;           (f1 "A/")
;;           (f2 "B/")
;;           (p1 (expand-file-name f1 wdir))
;;           (p2 (expand-file-name f2 wdir)))
;;      (progn (cond ((file-regular-p p1) (delete-file (directory-file-name p1)))
;;                   ((file-directory-p p1) (delete-directory p1)))
;;             (cond ((file-regular-p p2) (delete-file (directory-file-name p2)))
;;                   ((file-directory-p p2) (delete-directory p2)))
;;             (make-directory p1)
;;             (dcache-reset)
;;             (and
;;              ;; absolute name test
;;              (let ((c1 (dcache-of p1))) ;force fetch dcache
;;                (copy-directory p1 p2)
;;                (let ((c2 (dcache-of p2 t))) ;unforced get dcache copy
;;                  (and (dcachep c2)
;;                       (dcache-equal c1 c2)))) ;old dcache should be equal to new dcache (except filename)
;;              )))))

(defadvice rename-file (around fcache-rename-file (file newname &optional ok-if-already-exists) activate)
  "Move dcache and fcache from FILE to NEWNAME."
  ad-do-it
  (let ((dcache (dcache-of file t)))
    (if dcache
        (dcache-copy-cb dcache newname)
      (let ((fcache (fcache-of file t)))
        (fcache-copy-cb fcache file newname)))))

(defadvice delete-file (around fcache-delete-file (filename &optional trash) activate)
  "Delete fcache of file that gets deleted."
  ad-do-it)

(defadvice add-name-to-file (around fcache-add-name-to-file (file newname &optional ok-if-already-exists) activate)
  "Reuse fcache of FILE in NEWNAME."
  ad-do-it)

(defadvice make-symbolic-link (around fcache-make-symbolic-link (filename linkname &optional ok-if-already-exists) activate)
  "Reuse fcache of FILENAME that gets sym-linked from LINKNAME."
  ad-do-it)

;; ---------------------------------------------------------------------------

(defcustom fcache-default-file-name ".fcache"
  "Default filename for file caches."
  :group 'dfcache)

(defcustom fcache-common-directory "~/.emacs.d/fcache"
  "Default common directory for storing file caches."
  :group 'dfcache)

;; TODO Merge with Semantic(DB)
(defun fcache-save (directory)
  (interactive "DSave in directory: ")
  "Save File System Cache of DIRECTORY defaulting to `default-directory'."
  (unless directory
    (setq directory default-directory))
  (let ((cache-file (expand-file-name fcache-default-file-name directory)))
    (unless (and (file-accessible-directory-p directory)
                 (file-writable-p directory))
      ;; we must save to common directory instead
      (make-directory fcache-common-directory t)
      (setq cache-file (expand-file-name (replace-regexp-in-string "/" "!" cache-file)
                                         fcache-common-directory))) ;convert ?/ to ?!
    (save-window-excursion
      (find-file-literally cache-file)
      (erase-buffer)
      (print (dcache-of directory)
             (current-buffer))
      (save-buffer))))
;; Use: (fcache-save "/bin")
;; Use: (fcache-save (elsub "mine/"))

;; TODO Merge with Semantic(DB)
(defun fcache-load (directory)
  "Load File System Cache of DIRECTORY defaulting to `default-directory'."
  (let ((cache-file (expand-file-name fcache-default-file-name directory)))
    (unless (file-accessible-directory-p directory) ;
      (setq cache-file (replace-regexp-in-string "/" "!" cache-file))) ;convert ?/ to ?!
    (read cache-file)
    ))
;; Use: (fcache-load (elsub "mine/"))

(defun elp-benchmark-fcache ()
  (interactive)
  (let ((default-directory "~/Work/MATLAB/EMD/EMDs/src"))
    (elp-reset-all)
    (elp-instrument-package "fcache-")
    (elp-instrument-package "dcache-")
    (call-interactively 'uproj-build-and-maybe-run-target)
    ))
;; Use: (elp-benchmark-fcache)
;; Use: (elp-results)
;; Use: (fcache-get-properties (fcache-of (expand-file-name "~/Work/MATLAB/EMD/EMDs/src")))

(when nil
  (eval-when-compile (assert-error "" (fcache-follow-link (fcache-of (elsub "mine/tscan-tests/faulty-link")))))
  (eval-when-compile (assert-nil (fcache-follow-link (fcache-of (elsub "mine/tscan-tests/faulty-link")) t)))

  (eval-when-compile (assert-error "" (dcache-rget-fcache "ls" nil)))
  (eval-when-compile (assert-t (progn (dcache-reset)
                                      (let ((fcache (fcache-of "/bin/ls")))
                                        (eq fcache
                                            (dcache-rget-fcache "ls"
                                                                (fcache-parent-dcache fcache)))))))

  (eval-when-compile (assert-t (progn (dcache-reset) (fcachep (fcache-rget "ls" "/bin")))))
  (eval-when-compile (assert-nil (progn (dcache-reset) (fcachep (fcache-rget "ls" "/bin" t)))))
  (eval-when-compile (assert-error "" (progn (dcache-reset) (fcachep (fcache-rget "fls" "/bin")))))
  (eval-when-compile (assert-error "" (progn (dcache-reset) (fcachep (fcache-rget "ls" "/binx")))))
  (eval-when-compile (assert-nil (progn (dcache-reset) (fcachep (fcache-rget "fls" "/bin" nil t)))))
  (eval-when-compile (assert-nil (progn (dcache-reset) (fcachep (fcache-rget "ls" "/binx" nil t)))))

  (eval-when-compile (assert-nil (let ((file (elsub "mine/tags")))
                                   (when (file-exists-p file)
                                     (rm-file file))
                                   (fcache-of file nil t)
                                   )))
  (eval-when-compile (assert-t (and (eq (fcache-of "~")
                                        (fcache-of (expand-file-name "~/")))
                                    (eq (fcache-of "~/")
                                        (fcache-of "~")))))
  (eval-when-compile (assert-t (fcachep (fcache-of "/bin/ls"))))
  (eval-when-compile (assert-error "" (fcache-of "/bin/lsxx")))

  (eval-when-compile (assert-t (fcache-ftype (fcache-of "/bin/"))))
  (eval-when-compile (assert-nil (fcache-ftype (fcache-of "/bin/ls"))))
  (eval-when-compile (assert-nil (fcache-ftype (fcache-of "/bin/ls"))))

  (eval-when-compile (assert-t (string-equal (dcache-uniquify-path "~")
                                             (dcache-uniquify-path "~/"))))

  (eval-when-compile (assert-t (let ((table (dcache-reset))) ;safest to reset all if we change something
                                 (and (hash-table-p table)
                                      (zerop (hash-table-count table))))))

  (eval-when-compile
    (let ((dir "/bin")
          (filename "ls"))
      (assert-equal dir
                    (dcache-fname
                     (fcache-parent-dcache
                      (fcache-of (expand-file-name filename dir)))))))

  (eval-when-compile (when (file-exists-p "/bin/ls")
                       (let* ((filename "/bin/ls")
                              (fcache (fcache-of filename))
                              (name :targets)
                              (value '("all")))
                         (fcache-set-property fcache name value)
                         (assert-equal value
                                       (fcache-get-property fcache name)))))

  (eval-when-compile (when (file-directory-p "~/justcxx")
                       (let* ((filename "~/justcxx")
                              (fcache (fcache-of filename))
                              (name :history)
                              (value "clean"))
                         (assert-equal
                          `(,value)
                          (progn
                            (fcache-set-property fcache name nil)
                            (fcache-add-to-history-property fcache name value)
                            (fcache-get-property fcache name))))))

  (eval-when-compile (assert-t (dcachep (dcache-of "/bin"))))
  (eval-when-compile (assert-nil (progn (dcache-reset) (dcache-of "~/" t))))
  (eval-when-compile (assert-nil (progn (dcache-reset) (dcache-of "~/_" t))))
  (eval-when-compile (assert-error "" (progn (dcache-reset) (dcache-of "~/_" nil))))
  (eval-when-compile (assert-nil (progn (dcache-reset) (dcache-of "~/_" nil t))))
  (eval-when-compile (assert-t (dcachep (progn (dcache-reset) (dcache-of "~/")))))
  (eval-when-compile (assert-t (dcachep (progn (dcache-reset) (dcache-of "~/") (dcache-of "~/" t)))))

  (eval-when-compile
    (assert-t
     (let* ((wdir "/tmp")               ;working directory
            (f1 "A/")
            (f2 "B/")
            (p1 (expand-file-name f1 wdir))
            (p2 (expand-file-name f2 wdir)))
       (progn (cond ((file-regular-p p1) (delete-file (directory-file-name p1)))
                    ((file-directory-p p1) (delete-directory p1)))
              (cond ((file-regular-p p2) (delete-file (directory-file-name p2)))
                    ((file-directory-p p2) (delete-directory p2)))
              (make-directory p1)
              (dcache-reset)
              (and
               ;; absolute name test
               (let ((c1 (dcache-of p1)))
                 (rename-file p1 p2)
                 (let ((c2 (dcache-of p2 t)))
                   (and (dcachep c2)
                        (string-equal (dcache-uniquify-path p2)
                                      (dcache-fname c2))
                        (dcache-equal c1 c2)))) ;old dcache should be same as new dcache
               ;; undo using relative name test
               (let ((default-directory wdir))
                 (let ((c2 (dcache-of f2)))
                   (rename-file f2 f1)
                   (let ((c1 (dcache-of f1 t)))
                     (and (dcachep c1)
                          (string-equal (dcache-uniquify-path f1)
                                        (dcache-fname c1))
                          (dcache-equal c2 c1))) ;old dcache should be same as new dcache
                   )))))))

;;; Benchmark
  (eval-when-compile
    (let ((dirname "/usr/bin")
          )
      (message "Speed-Up: %2.1f" (/ (bench (directory-files dirname))
                                    (bench (fcache-dir-files dirname nil nil))))
      (message "Speed-Up: %2.1f" (/ (bench (directory-files dirname))
                                    (bench (fcache-dir-files dirname nil "x"))))
      (message "Speed-Up: %2.1f" (/ (bench (directory-files dirname))
                                    (bench (fcache-dir-files dirname t "x"))))
      )
    )

;;; Benchmark
  (eval-when-compile
    (let ((dirname "/usr/bin"))
      (message "Speed-Up: %2.1f" (/ (bench (directory-files dirname))
                                    (bench (fcache-dir-subs dirname)))))
    )
  )
(provide 'fcache)
