;; md5-ext.el --- MD5 Extensions.
;; coding: utf-8
;; Author: Per Nordlöw

(require 'hex-util)

(defun md5-raw (object &optional start end coding-system noerror)
  "Return MD5 message digest of OBJECT, a buffer or string, as a
  raw unibyte string."
  (decode-hex-string (md5 object start end coding-system noerror))
  )
;; Use: (md5-raw "al")
