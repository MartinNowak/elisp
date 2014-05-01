;;; main-function.el --- Detect files having main functions.
;; Copyright (C) 2007 Per Nordlöw <per.nordlow@gmail.com>

(require 'cscan)

;;; C/C++/Objective-C/D
(defcustom c-like-main-function-regexp "^\\(?:void\\|int\\)?[[:space:]]*main[[:space:]]*("
  "Regexp matching C-style main function.")
;; (cscan-file "~/f.cpp" c-like-main-function-regexp 'code t)
;; (cscan-file "~/bin/helloworld.d" c-like-main-function-regexp 'code t)
(defun file-c-main-function (&optional filename)
  "Return position (BEG END) of main function in FILENAME or nil if none present."
  (let ((filename (or filename
                      buffer-file-name)))
    (and (file-match filename '(C C++ Objective-C D) 'name-recog)
         (cscan-file filename c-like-main-function-regexp nil t)))) ;TODO: Set `cscan-file' argument `ctx' to `code' when this logic in cscan is fixed
;; (file-c-main-function "~/cognia/tests/t_semnet.cpp")
;; Use: (file-c-main-function "~/justd/fs.d")
;; Use: (file-c-main-function "~/justd/test/t_array.d")

;;; Haskell
(defconst haskell-main-function-regexp "^[[:space:]]*main[[:space:]]*="
  "Regexp matching Haskell-style main function.")
;; (cscan-file "~/bin/hello.hs" haskell-main-function-regexp 'code t)
(defun file-haskell-main-function (filename)
  "Return position (BEG END) of main function in FILENAME or nil if none present."
  (let ((filename (or filename
                      buffer-file-name)))
    (and (file-match filename '(Haskell) 'name-recog)
         (cscan-file filename haskell-main-function-regexp 'code t))))
;; (file-haskell-main-function "~/bin/hello.hs")

;;; Go
(defconst go-main-function-regexp "^[[:space:]]*func[[:space:]]*main[[:space:]]*([[:space:]]*)"
  "Regexp matching Go-style main function.")
;; (cscan-file (elsub "mine/tscan-tests/utf16.go") go-main-function-regexp 'code t)
(defun file-go-main-function (filename)
  "Return position (BEG END) of main function in FILENAME or nil if none present."
  (let ((filename (or filename
                      buffer-file-name)))
    (and (file-match filename '(Go) 'name-recog)
         (cscan-file filename go-main-function-regexp 'code t))))
;; (file-go-main-function (elsub "mine/tscan-tests/utf16.go"))

(defun file-main-function (filename &optional lang)
  "Return position (BEG END) of main function in FILENAME or nil if none present.
LANG is gueesed langugage."
  (interactive "fFile: ")
  (cond ((or (or (string= lang "c")
                 (file-C-source-p filename))
             (or (string= lang "c++")
                 (file-C++-source-p filename))
             (string= lang "objective-c")
             (string= lang "objective-c++")
             (or (string= lang "d")
                 (file-D-source-p filename)))
         (file-c-main-function filename)
         )
        ((string= lang "go")
         (file-go-main-function filename)
         )
        ((string= lang "haskell")
         (file-haskell-main-function filename)
         )
        (t
         (file-c-main-function filename)
         )))
;; Use: (file-main-function "~/cognia/drep.d")
;; Use: (file-main-function "~/cognia/t_array.d")

(provide 'main-function)
