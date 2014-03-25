;;; -*- coding: iso-2022-7bit -*-

;; Copyright (C) 2006  by Seiji Zenitani

;; Author: Seiji Zenitani <zenitani@mac.com>
;; $Id$
;; URL: http://homepage.mac.com/zenitani/elisp-j.html#utf-sty

;; utf $B%Q%C%1!<%8(B (utf.sty) $B$rJXMx$K;H$&$?$a$N4X?t$rDs6!$7$^$9!#(B
;; M-x utf-sty-encode-buffer, utf-sty-encode-region $B$O(B
;; $B%P%C%U%!!&%j!<%8%g%sFb$N%F%-%9%H$r(B \UTF{...} $B$J$I$KJQ49$7$^$9!#(B
;; M-x utf-sty-decode-buffer, utf-sty-decode-region $B$O(B
;; $B$=$N5U$N=hM}$r9T$$$^$9!#(B
;; 
;; $BNc!K?9$(Dl?$B30(B $B"N(B $B?9(B\UTF{9DD7}$B30(B
;; 
;; $B$^$?!"(Bprefix$B!J(BC-u$B!K$rIU$1$F;H$&$3$H$b$G$-$^$9!#(B
;; C-u M-x utf-sty-encode-buffer = M-x utf-sty-decode-buffer

;; $B$3$N%U%!%$%k$O(B GPL $B%i%$%;%s%9(B v2 $B$N$b$H$G:FG[I[2DG=$G$9!#(B

;;; Code:

(defun utf-sty-encode-buffer (&optional arg)
  (interactive "*p")
  (utf-sty-encode-region (point-min) (point-max) arg)
  )
(defun utf-sty-decode-buffer (&optional arg)
  (interactive "*p")
  (utf-sty-decode-region (point-min) (point-max) arg)
  )

(defun utf-sty-encode-region (start end &optional arg)
  (interactive "*r\np")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (cond
       ((= arg 1) (utf-sty-encode1)) ; M-x
       ((= arg 4) (utf-sty-decode1)) ; C-u M-x
       ))))

(defun utf-sty-decode-region (start end &optional arg)
  (interactive "*r\np")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (cond
       ((= arg 1) (utf-sty-decode1)) ; M-x
       ((= arg 4) (utf-sty-encode1)) ; C-u M-x
       ))))

(defun utf-sty-encode1()
  (goto-char (point-min))
  (while (not (eobp))
    (let* ((char (char-after))
           (charset (char-charset char))
           ;; (charset-description charset)
           ;; (split (split-char char))
           (pos (point))
           (unicode nil))
      (unless
          (memq charset '(ascii japanese-jisx0208 katakana-jisx0201))
        (if (or (< char 256)
                (memq 'mule-utf-8 (find-coding-systems-region pos (1+ pos)))
                (get-char-property pos 'untranslated-utf-8))
            (setq unicode (or (get-char-property pos 'untranslated-utf-8)
                              (encode-char char 'ucs))))
        (when unicode
          (delete-char 1)
          (cond
           ((eq charset 'korean-ksc5601)
            (insert-string (format "\\UTFK{%04X}" unicode)))
           ((eq charset 'chinese-gb2312)
            (insert-string (format "\\UTFC{%04X}" unicode)))
           ((eq charset 'chinese-big5-1)
            (insert-string (format "\\UTFT{%04X}" unicode)))
           (t
            (insert-string (format "\\UTF{%04X}" unicode)))
           ))
        )
      (if (not (eobp))(forward-char))
      )))

(defun utf-sty-decode1()
  (goto-char (point-min))
  (while (re-search-forward
          "\\\\\\(UTF\\|UTFK\\|UTFT\\|UTFC\\)\{\\([0-9a-f][0-9a-f][0-9a-f][0-9a-f]\\)\}"
          nil t 1)
    (let ((str (match-string 2)))
      (replace-match ""  t nil)
      (if (stringp str) (ucs-insert str))
      )))

(provide 'utf-tool)

;; utf-tool.el ends here.