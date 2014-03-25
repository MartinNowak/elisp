;;; -*- Mode: Emacs-Lisp -*-

;;;; Portable Pathname Abstraction
;;;; DOS (Microsoft Windows) Pathnames

;;; Original author: Ben Goetter <goetter@mazama.net>
;;; I place this code in the Public Domain, and disclaim all
;;; warranties.  Do with it what you will.


(define-file-system-type 'dos
  '(parse-namestring . ntfs/parse-namestring)
  '(origin-namestring . ntfs/origin-namestring)
  '(directory-namestring . ntfs/directory-namestring)
  '(file-namestring . ntfs/file-namestring)
  )


;;; FAT32 vs NTFS
;;; qv http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dnfiles/html/msdn_longfile.asp
;;; http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/fs/naming_a_file.asp
;;;
;;; File and directory names may be up to 255 characters long on FAT file systems and 256 characters on NTFS.
;;; Full pathnames may be up to 260 characters long. 
;;; The backslash (\) is the path separator. 
;;; File and directory names on the Protected-Mode FAT file system may consist of letters, digits, spaces, and these characters: 
;;;    $%'-_@~`!{}()#&+,;=[]. 
;;; Note that periods are allowed in file and directory names, as long as they are accompanied by other characters. 
;;; For example, .text is perfectly legal. 
;;;
;;; On NTFS, file and directory names may consist of any character except the following characters:
;;;    "/\*?<>|:  
;;;
;;; Although file and directory names are not case-sensitive, their case is preserved.


;;; Unix module defines HOME, ROOT as origins. `Dos' (NTFS, actually...) adds:
;;;     CWD for root on current-working-drive, 
;;;     "A:" etc for the drive-letter (not root)
;;;     "A:\\" for root-on-drive-letter
;;;     "\\\\server\\share" for UNC
;;; Consider adding one for /My Documents/ origin
;;; (xemacs supports the Unix ~ = HOME, and so calls that ~/My Documents/)

;;; Examples of DOS-type pathnames
;;;    a.c -> (nil nil "a.c")
;;;    dir\a.c -> (nil "dir" "a.c")
;;;    \dir\dir2\a.c -> (cwd ("dir" "dir2") "a.c")
;;;    C:a.c -> ("C:" nil "a.c")
;;;    C:\dir\dir2\a.c -> ("C:\\" ("dir" "dir2") "a.c")
;;;    C:dir2\a.c -> ("C:" "dir2" "a.c")
;;;    \\server\share\dir\a.c -> ("\\\\server\\share" "dir" "a.c")
;;;    C: -> ("C:" nil nil)
;;;    C:\ -> ("C:\\" nil nil)
;;;     \ -> (cwd nil nil)
;;;    \\server\share -> ("\\\\server\\share" nil nil)

;;; Top level entry point: given a full namestring, return a pathname.
;;; Namestring /may/ contain a devicename - a drive letter

(defun ntfs/parse-namestring (namestring)
  (let ((ntfs/*namestring* namestring)
        (len (length namestring)))
    (cond ((= 0 len) (make-pathname nil nil nil))
          ((= 1 len) (ntfs/parse-namestring-1 namestring))
          ((= 2 len) (ntfs/parse-namestring-2 namestring))
          (t (ntfs/parse-namestring-n namestring)))))

(defun ntfs/parse-namestring-1 (namestring)
  (let ((char (aref namestring 0)))
    (cond ((eq ?\\ char)
           (make-pathname 'cwd nil nil))
          ((eq ?. char)
           (make-pathname nil nil nil))
          ((ntfs/legal-char-p char)
           (ntfs/parse-filename nil nil namestring))
          (t (ntfs/bad-namestring)))))

(defun ntfs/parse-namestring-2 (namestring)
  (let ((char0 (aref namestring 0))
        (char1 (aref namestring 1)))
    (cond ((eq ?: char1)
           (if (ntfs/drive-name-p char0)
               (make-pathname (upcase namestring) nil nil)
               (ntfs/bad-namestring)))
          ((eq ?\\ char0)
           (ntfs/parse-namestring+origin 'cwd
                                         (substring namestring 1)))
          (t (ntfs/parse-namestring+origin nil namestring)))))

(defun ntfs/parse-namestring-n (namestring)
  (let ((char0 (aref namestring 0)) (char1 (aref namestring 1)))
    (cond ((eq ?: char1)
           (if (ntfs/drive-name-p char0)
               (let ((end (if (eq ?\\ (aref namestring 2)) 3 2)))
                 (ntfs/parse-namestring+origin
                  (upcase (substring namestring 0 end))
                  (substring namestring end)))
               (ntfs/bad-namestring)))
          ((and (eq ?\\ char0) (eq ?\\ char1))
           (ntfs/parse-unc-namestring (substring namestring 2)))
          ((eq ?\\ char0)
           ;; This and similar redundancy between the various LENGTH
           ;; cases ensures that all valid leading backslashes are
           ;; eaten before sub-parsing begins.
           (ntfs/parse-namestring+origin 'cwd
                                         (substring namestring 1)))
          (t
           ;; Generate no origin.  Subsequent directory parsing code
           ;; may amend this to CWD.
           (ntfs/parse-namestring+origin nil namestring)))))

;;; Below this point the colon character is illegal.  PARSE-NAMESTRING
;;; handles its only acceptable usage.

(defun ntfs/parse-unc-namestring (namestring)
  (let ((directory (split-string namestring "[\\]")))
    ;; test for bogus characters in any directory or file component
    (mapc (lambda (s) 
            (let ((index 0) (limit (length s)))
              (while (< index limit)
                (if (not (ntfs/legal-char-p (aref s index)))
                    (ntfs/bad-namestring))
                (setq index (+ index 1)))))
          directory)
    ;; If it began with the UNC prefix, then it had better have at
    ;; least SERVER and SHARE
    (if (or (< (length directory) 2) 
            (string= "" (car directory)) 
            (string= "" (cadr directory)))
        (ntfs/bad-namestring))
    (ntfs/parse-dirlist+origin
     (concat "\\\\" (car directory) "\\" (cadr directory))
     (cddr directory))))


;;; Given a parsed origin and the right-hand-side remains of a namestring, return a pathname
;;; This namestring may not have leading backslashes
(defun ntfs/parse-namestring+origin (origin namestring)
  (let ((directory (split-string namestring "[\\]")))
    ;; test for bogus characters in any directory or file component
    (mapc (lambda (s) 
            (let ((index 0) (limit (length s)))
              (if (> limit 256)
                  (ntfs/bad-namestring))
              (while (< index limit)
                (if (not (ntfs/legal-char-p (aref s index)))
                    (ntfs/bad-namestring))
                (setq index (+ index 1)))))
	  directory)
    (ntfs/parse-dirlist+origin origin directory)))


;; Given a parsed origin and the right-hand-side remains of a namestring that's been burst into a list,
;; return a pathname
(defun ntfs/parse-dirlist+origin (origin directory)
  (cond
   ((null directory) )
   ((string= "" (car directory))
    (if (null (cdr directory))
	;; parse-namestring+origin was given an empty string
	(setq directory nil)
      ;; there was an inappropriate double-backslash within the path
      (ntfs/bad-namestring))))
  (cond
   ((null directory)
    (make-pathname origin nil nil))
   (t
    (let* ((rev (reverse directory))
	   (last (car rev)))
      (cond
       ((or (string= "" last) (string= "." last))
	;; dir ended in / or /. - no file
	(make-pathname origin (ntfs/norm-dir (cdr rev)) nil))
       ((string= ".." last)
	;; dir ended in /.. - no file - pass the .. along for normalization
	(make-pathname origin (ntfs/norm-dir rev) nil))
       (t
	(ntfs/parse-filename origin (ntfs/norm-dir (cdr rev)) last)))))))


;; Given a parsed origin, a parsed directory, and a partially validated file,
;; return a pathname
(defun ntfs/parse-filename (origin directory file)
  (if (null file)
      (make-pathname origin directory file)
    (let ((len (length file)))
      (if (> len 0)
	  (case (aref file (- len 1))
	    ;; filenames may not end with a period or space
	    ((?. ?\ ) (ntfs/bad-namestring))
	    (t (make-pathname origin directory file)))
	(make-pathname origin directory nil)))))


;; Normalize a directory sequence, handling ., .., and bogus empty strings (corresponding to // within)
;; This expects the directory sequence already reversed
(defun ntfs/norm-dir (reversed-directory)
  (let ((rev reversed-directory)
	(h nil)
	(new nil))
    (while (not (null rev))
      (setq h (car rev))
      (cond
       ((string= h "") 
	;; internal element will be "" if form is ...foo//bar...
	(ntfs/bad-namestring))
       ((string= h ".") )
       ((string= h "..") 
	(setq rev (cdr rev)) 
	(if (null rev) (ntfs/bad-namestring)))
       (t (setq new (cons h new))))
      (setq rev (cdr rev)))
    new))

(defun ntfs/legal-char-p (char)
  (not (memq char '(?/ ?\\ ?* ?? ?> ?< ?:))))

;;; DOS brain damage

(defun ntfs/reserved-name-p (name)
  (member (upcase (car (split-string name "\\.")))
          '("CON" "PRN" "AUX" "NUL" "COM1" "COM2" "COM3" "COM4" "COM5"
            "COM6" "COM7" "COM8" "COM9" "LPT1" "LPT2" "LPT3" "LPT4"
            "LPT5" "LPT6" "LPT7" "LPT8" "LPT9" "CLOCK$")))

(defun ntfs/drive-name-p (char)
  (or (and (<= ?a char) (<= char ?z))
      (and (<= ?A char) (<= char ?Z))))

(defvar ntfs/*namestring* nil)

(defun ntfs/bad-namestring ()
  (error "Malformed NTFS namestring: %S" ntfs/*namestring*))

(defun ntfs/origin-namestring (pathname)
  (let ((origin (pathname-origin pathname)))
    (cond ((stringp origin) origin)
          ((eq origin 'cwd) "\\")
          ((not origin) "")
          (t (error "Unrecognized NTFS pathname origin: %S" origin)))))

(defun ntfs/directory-namestring (pathname)
  (let ((directory (pathname-directory pathname)))
    (if directory
        (mapconcat (lambda (component)
                     (concat (ntfs/file->namestring component)
                             "\\"))
                   directory
                   "")
        "")))

(defun ntfs/file-namestring (pathname)
  (let ((file (pathname-file pathname)))
    (if file
        (ntfs/file->namestring file)
        "")))
