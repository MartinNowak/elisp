;;; Return an HMAC-SHA1 authentication code for KEY and MESSAGE.
;;; 
;;; KEY and MESSAGE must be unibyte strings.  The result is a unibyte
;;; string.  Use the function `encode-hex-string' or the function
;;; `base64-encode-string' to produce human-readable output.
;;; 
;;; See URL:<http://en.wikipedia.org/wiki/HMAC> for more information
;;; on the HMAC-SHA1 algorithm.
;;;
;;; Author: Derek Upham - sand (at) blarg.net
;;;
;;; Copyright: This code is in the public domain.

(require 'sha1)

(defun hmac-sha1 (key message)
  "Return an HMAC-SHA1 authentication code for KEY and MESSAGE.

KEY and MESSAGE must be unibyte strings.  The result is a unibyte
string.  Use the function `encode-hex-string' or the function
`base64-encode-string' to produce human-readable output.

See URL:<http://en.wikipedia.org/wiki/HMAC> for more information
on the HMAC-SHA1 algorithm."
  (when (multibyte-string-p key)
    (error "key must be unibyte" key))
  (when (multibyte-string-p key)
    (error "message must be unibyte" message))
  (let* ((+hmac-sha1-block-size-bytes+ 64) ; SHA-1 uses 512-bit blocks
         (opad (make-vector +hmac-sha1-block-size-bytes+ #x5c))
         (ipad (make-vector +hmac-sha1-block-size-bytes+ #x36))
         ;; Handle padding of the key by copying over pad bytes
         (key-block (make-vector +hmac-sha1-block-size-bytes+ 0)))

    ;; Standard operating procedure for dealing with a too-long key.
    (when (< +hmac-sha1-block-size-bytes+ (length key))
      (setq key (sha1 key nil nil t)))

    (dotimes (i (length key))
      (aset key-block i (aref key i)))

    (dotimes (i +hmac-sha1-block-size-bytes+)
      (aset ipad i (logxor (aref ipad i) (aref key-block i)))
      (aset opad i (logxor (aref opad i) (aref key-block i))))

    (sha1 (concat opad
		  (sha1 (concat ipad message)
			nil nil t))
          nil nil t)))

(provide 'hmac-sha1)
