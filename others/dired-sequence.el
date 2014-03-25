;;; dired-sequence.el --- Handle files that are named in a sequential manner in dired

;;; Commentary:
;; 

;; Media files, like image files and sound files are often named
;; according to numerical patterns.  Some types of operations on media
;; files are lossy, resulting in missing files, files not being named
;; in the intended order, etc.

;; One example is image files scanned from a book.  Each page gets a
;; file name like 0001.djvu for instance.  If the scanner accidentaly
;; double-feeds pages, image file names no longer match book page
;; numbers. Another example is converting compact discs to audio
;; files.

;; This library is intended to help fix issues like these.

;;Some concepts:

;;- Mark Expression: Used both for matching filenames, and generating
;;new filenames, therefore a string compliant with the "format"
;;function rather than a normal regexp is used.  example 00-%4d.djvu ,
;;%4d is interpreted for pattern matching.  This will match filenames
;;looking like 00-0001.djvu etc.  Maybe it would be useful with a more
;;complete regexp syntax, but so far the current syntax is convenient
;;and has worked well.

;; - Gap: A gap in the sequential numbering of files, some files are
;;aparently missing in the middle of a sequence

;; - Offset: Used when offseting sequential filenames up or down in
;;sequence.

;;; History:

;; 2009-08-7: v0.1

;;; Code:

(defvar dired-sequence-history nil)
(defvar dired-sequence-default nil)

(defun dired-sequence-read-mark-expression ()
  "Read a mark-expression from minibuffer.
suitable for interactive declarations"
  (setq dired-sequence-default
        (read-string
         (format "Mark expression(%s): " dired-sequence-default)
         nil 'dired-sequence-history dired-sequence-default)))

(defun dired-sequence-find-gap (mark-expression)
  "Move cursor to next sequence gap.
Argument MARK-EXPRESSION see commentary."
  (interactive
   (list (dired-sequence-read-mark-expression))
   (dired-sequence-mark-helper mark-expression (lambda()(dired-next-line 1) ))))

(defun dired-sequence-mark (mark-expression)
  "Mark files that are sequential, until a gap is encountered.
MARK-EXPRESSION see commentary."(interactive
   (list (dired-sequence-read-mark-expression))
   (dired-sequence-mark-helper mark-expression (lambda()(dired-mark 1)))))

(defun dired-sequence-wdired-offset-files (mark-expression offset)
  "Iterate previously marked files.
According to MARK-EXPRESSION, offset the filenames by OFFSET
using wdired."
  (interactive
   (progn
     (unless (eq major-mode 'wdired-mode) (error "Dired buffer must be editable"))
     (list (dired-sequence-read-mark-expression)
           (string-to-int (read-string "Offset: " "1")))))
  (dired-map-over-marks
   (progn
     (dired-move-to-filename)
     (let*
         ((newname (dired-sequence-offset-filename mark-expression offset)))
       (insert newname)
       (kill-line)
       ))
   nil
   ))

(defun dired-sequence-mark-helper (mark-expression fn)
  "Mark acording to given rule.
Argument MARK-EXPRESSION see commentary.
Argument FN function to call for each file in the sequence."
  ;;TODO interactive
  (let ((filename-matching t))
    (while filename-matching
      (let*
          ((next-expected (dired-sequence-offset-filename mark-expression 1))
           )
        ;;        (dired-mark 1)
        (funcall fn )
        (setq filename-matching (eq 0 (string-match next-expected (dired-get-filename t))))))))


(defun dired-sequence-offset-filename (mark-expression offset)
  "Get file name at point, interpret is as part of a sequence.
described by MARK-EXPRESSION, offset the filename by OFFSET"
  ;;file at point
  (let*
      ((cur-file-name (dired-get-filename t))
       ;;figure out start val of counter
       (mymatch (string-match (dired-sequence-format-string-to-regexp  mark-expression) cur-file-name))
       (matchval (match-string 1 cur-file-name))
       (counter (+ offset (string-to-int matchval)))
       ;;see if current file matches,  else quit
       (expected-cur-file-name (format mark-expression counter))
       )
    expected-cur-file-name)
  )


(defun dired-sequence-format-string-to-regexp (format-string)
  "Xxx%Xdyy to xxx([0-9]{d})yyy.
Argument FORMAT-STRING ."
  (let*
      ((matchstr (string-match "\\([^%]*\\)%\\([0-9]+\\)d\\(.*\\)" format-string))
       (a (match-string 1 format-string))
       (b (match-string 3 format-string))
       (c (match-string 2 format-string))
       (result (concat  a "\\([0-9]\\{" c "\\}\\)" b ))
       )
    result
    ))

(provide 'dired-sequence-mark)

;;; dired-sequence-mark.el ends here

(provide 'dired-sequence)

;;; dired-sequence.el ends here
