;;; -*- Mode: Emacs-Lisp -*-

;;;; Portable Pathname Abstraction
;;;; Unix Pathnames

;;; This code is written by Taylor Campbell and placed in the Public
;;; Domain.  All warranties are disclaimed.

(eval-when-compile (require 'cl))       ;flet

(define-file-system-type 'unix
  '(parse-namestring . unix-fs/parse-namestring)
  '(origin-namestring . unix-fs/origin-namestring)
  '(directory-namestring . unix-fs/directory-namestring)
  '(file-namestring . unix-fs/file-namestring)
  '(expand-pathname-origin . unix-fs/expand-pathname-origin)
  )

(defun unix-fs/parse-namestring (namestring)
  (let ((len (length namestring)))
    (cond ((zerop len) (make-pathname nil nil nil))
          ((= len 1)
           (let ((char (aref namestring 0)))
             (cond ((eq char ?~) (make-pathname 'home nil nil))
                   ((eq char ?/) (make-pathname 'root nil nil))
                   ((eq char ?$)
                    (error "Malformed Unix namestring: %S" namestring))
                   ((eq char ?.) (make-pathname nil nil nil))
                   ;++ Should this be a file or a directory pathname?
                   (t (make-pathname nil nil namestring)))))
          (t (unix-fs/parse-namestring-origin namestring)))))

(defun unix-fs/parse-namestring-origin (namestring)
  (let ((char (aref namestring 0)))
    (cond ((eq char ?~)
           (unix-fs/parse-homedir-namestring namestring))
          ((eq char ?/)                 ;++ /. for root directory file?
           (unix-fs/parse-namestring-directory namestring 0 'root))
          ((eq char ?$)
           (unix-fs/parse-env-namestring namestring))
          ((eq char ?.)
           (unix-fs/parse-dot-namestring namestring))
          (t
           (unix-fs/parse-namestring-directory namestring
                                               ;; No leading slash.
                                               -1
                                               nil)))))

(defun unix-fs/parse-homedir-namestring (namestring)
  (let ((slash-index (string-match "/" namestring)))
    (if (not slash-index)
        (make-pathname `(home ,(substring namestring 1))
                       nil
                       nil)
        (unix-fs/parse-namestring-directory
         namestring
         slash-index
         (if (= slash-index 1)
             'home
             `(home ,(substring namestring 1 slash-index)))))))

(defun unix-fs/parse-env-namestring (namestring)
  (let ((slash-index (string-match "/" namestring)))
    (if (not slash-index)
        (make-pathname (unix-fs/env-origin (substring namestring 1))
                       nil
                       nil)
        (unix-fs/parse-namestring-directory
         namestring
         slash-index
         (unix-fs/env-origin
          (if (= slash-index 1)
              (error "Malformed Unix namestring: %S" namestring)
              (substring namestring 1 slash-index)))))))

(defun unix-fs/env-origin (var)
 (if (string= var "HOME")               ;Hmmm.
     'home
     var))

;;; This is messy because elisp has no reasonable looping constructs.
;;; What this code does is to strip any leading ./ components and turn
;;; any leading ../ components into 'back' origins.  However, if there
;;; is any leading //, it discards all of the ../ components entirely.

(defun unix-fs/parse-dot-namestring (namestring)
  (let ((len (length namestring))
        (index 0)
        (backs nil))
    (catch 'exit
      (flet ((if-at-end (file)
               (throw 'exit (make-pathname backs nil file)))
             (parse-directory ()
               (throw 'exit
                      (unix-fs/parse-namestring-directory namestring
                                                          (- index 1)
                                                          backs))))
        (while t
          (cond ((= index len)          ; At end; no trailing file
                 (if-at-end nil))
                ((not (eq ?. (aref namestring index)))
                 ;; Not a dot.  If it's a slash, we saw //, and this
                 ;; means that we jump back to the root directory.
                 ;; Otherwise we have no more backs (or dots) to deal
                 ;; with, so we move on to parsing the directory.
                 (if (eq ?/ (aref namestring index))
                     (setq index (+ index 1)
                           backs 'root)
                     (parse-directory)))
                ((= (+ index 1) len)    ; At end, with trailing "."
                 (if-at-end "."))
                ((not (eq ?. (aref namestring (+ index 1))))
                 ;; One but not two dots.  If we see a slash, this is a
                 ;; "." component, which we strip.  Otherwise, this is
                 ;; some other filename, and we start parsing the
                 ;; directories.
                 (if (eq ?/ (aref namestring (+ index 1)))
                     (setq index (+ index 2))
                     (parse-directory)))
                ((= (+ index 2) len)    ; At end, with trailing ".."
                 (if-at-end ".."))
                ((not (eq ?/ (aref namestring (+ index 2))))
                 ;; Two dots, but not followed by a slash; this is just
                 ;; a peculiarly named directory, so parse the
                 ;; directories.
                 (parse-directory))
                (t (setq index (+ index 3) ; Complete .. -- advance.
                         backs (cond ((null backs) 'back)
                                     ((eq backs 'back) '(back back))
                                     ;; *Bizarre* behaviour here.
                                     ;; Parent of root is root.
                                     ((eq backs 'root) 'root)
                                     (t (cons 'back backs)))))))))))

(defun unix-fs/parse-namestring-directory (namestring start origin)
  (let ((directory '())
        (index start))
    (while (setq start (+ index 1)
                 index (string-match "/" namestring start))
      (cond ((eq index start)
             (setq directory '()
                   origin 'root))
            ((not (and (eq index (+ start 1))
                       (eq ?. (aref namestring start))))
             (setq directory (cons (substring namestring start index)
                                   directory)))))
    (setq directory (nreverse directory))
    (make-pathname origin
                   (if (and (not origin)
                            (consp directory)
                            (equal (car directory) "."))
                       (cdr directory)
                       directory)
                   (if (= start (length namestring))
                       nil
                       (unix-fs/parse-namestring-file namestring
                                                      start)))))

;;; I want a better way to configure these than dynamic variables.
;;; There probably ought to be some pathname operation that reparses
;;; the name, or something like that.

(defvar unix-fs/parse-file-types nil)
(defvar unix-fs/parse-file-versions nil)

(defun unix-fs/parse-namestring-file (namestring start)
  (let ((version
         (and unix-fs/parse-file-versions
              (unix-fs/parse-namestring-version namestring start))))
    (let ((end (if version (car version) (length namestring)))
          (version (if version (cdr version) nil)))
      (if (not unix-fs/parse-file-types)
          (make-file (substring namestring start end)
                     nil
                     version)
          (unix-fs/parse-namestring-file-types namestring start end
                                               version)))))

(defun unix-fs/parse-namestring-file-types (namestring start end
                                                       version)
  (let ((parts (split-string (substring namestring start end)
                             "[.]")))
    (if (null parts)
        (make-file nil nil version)
        (make-file (car parts) (cdr parts) version))))

(defun unix-fs/parse-namestring-version (namestring start)
  (let ((index (string-match "\\.~\\([0-9]*\\)~\\'"
;++                          ;; No rx in older Emacsen.
;++                          (rx (: ".~" (submatch (* digit)) "~"
;++                                 string-end))
                             namestring
                             start)))
    (if index
        (cons index (string-to-int (match-string 1 namestring)
                                   10.))
        nil)))

(defun unix-fs/origin-namestring (pathname)
  (let ((origin (pathname-origin pathname)))
    (cond ((not origin) "")
          ((eq origin 'root) "/")
          (t (concat (unix-fs/*origin-namestring origin)
                     (if (or (pathname-file pathname)
                             ;++ nil/false pun
                             (pathname-directory pathname))
                         "/"
                         ""))))))

(defun unix-fs/*origin-namestring (origin)
  (cond ((stringp origin) (concat "$" origin))
        ((and (consp origin)
              (eq (car origin) 'home)
              (consp (cdr origin))
              (stringp (car (cdr origin)))
              (null (cdr (cdr origin))))
         (concat "~" (car (cdr origin))))
        ((eq origin 'home) "~")
        (t (error "Unrecognized Unix pathname origin: %S" origin))))

(defun unix-fs/directory-namestring (pathname)
  (let ((directory (pathname-directory pathname)))
    (if directory
        (mapconcat (lambda (component)
                     (concat (unix-fs/file->namestring component)
                             "/"))
                   (pathname-directory pathname)
                   "")
        "")))

(defun unix-fs/file-namestring (pathname)
  (let ((file (pathname-file pathname)))
    (if file
        (unix-fs/file->namestring file)
        "")))

(defun unix-fs/file->namestring (file)
  (concat (unix-fs/canonical-string (file-name file))
          (mapconcat (lambda (type)
                       (concat "." (unix-fs/canonical-string type)))
                     (file-types file)
                     "")
          (let ((version (file-version file)))
            (if version
                (concat ".~" (int-to-string version) "~")
                ""))))

(defun unix-fs/canonical-string (component)
  (if (symbolp component)
      (downcase (symbol-name component))
      ;; Otherwise, it will be a string.
      component))

;;;; Unix Pathname Origins

(defun unix-fs/expand-pathname-origin (origin)
  (let ((win (lambda (x)
               (pathname-as-directory (unix-fs/parse-namestring x)))))
    (cond ((eq origin 'home)
           (funcall win (expand-file-name "~/")))
          ((and (consp origin)
                (eq (car origin) 'home)
                (consp (cdr origin))
                (string-or-symbol-p (cadr origin))
                (null (cddr origin)))
           (funcall
            win
            (expand-file-name (concat "~"
                                      (if (symbolp (cadr origin))
                                          (symbol-name (cadr origin))
                                        (cadr origin))
                                      "/"))))
          ((string-or-symbol-p origin)
           (let ((value (getenv (if (symbolp origin)
                                    (symbol-name origin)
                                  origin))))
             (and value
                  (condition-case () (funcall win value)
                    (error nil)))))
          (t nil))))
