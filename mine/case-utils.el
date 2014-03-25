;;; case-utils.el --- Letter Casing Utilities.
;; Author: Per Nordlöw

;; SimplerWordCapitalization
;; See: http://www.emacswiki.org/cgi-bin/wiki/SimplerWordCapitalization

(defun downcase-any (x)
  "Generalized `downcase' of X.
X can be either a string, symbol or list of such elements."
  (cond ((stringp x)
         (downcase x))
        ((symbolp x)
         (intern (downcase (symbol-name x))))
        ((listp x)
         (mapcar 'downcase-any x))
        ;; TODO: Activate
        ;; ((vectorp x)
        ;;  (list-to-vector (mapcar 'downcase-any x)))
        ))
(eval-when-compile
  (assert-equal "xx" (downcase-any "XX"))
  (assert-equal '("xx") (downcase-any '("XX")))
  (assert-equal '(("xx")) (downcase-any '(("XX"))))
  ;; (assert-equal 'xx (downcase-any 'XX))
  )

(defun upcased-p (x)
  "Return non-nil if X is upcased."
  (cond ((stringp x) (string-equal (upcase x) x))
        ((sequencep x) (eval `(every-p (mapcar 'upcased-p ',x))))
        (t (error "Cannot handle x of type %s" (type-of x)))))
(defalias 'upcased? 'upcased-p)
;; Use: (upcased-p '("a" "b")) => nil
;; Use: (upcased-p '("a" "B")) => nil
;; Use: (upcased-p '("A" "B")) => t

(defun downcased-p (x)
  "Return non-nil if X is downcased."
  (cond ((stringp x) (string-equal (downcase x) x))
        ((sequencep x) (eval `(every-p (mapcar 'downcased-p ',x))))
        (t (error "Cannot handle x of type %s" (type-of x)))))
(defalias 'downcased? 'downcased-p)
;; Use: (downcased-p '("a" "b")) => t
;; Use: (downcased-p '("a" "B")) => nil

(defun capitalized-p (x)
  "Return non-nil if X is capitalized."
  (cond ((stringp x) (string-equal (capitalize x) x))
        ((sequencep x) (eval `(every-p (mapcar 'capitalized-p ',x))))
        (t (error "Cannot handle x of type %s" (type-of x)))))
(defalias 'capitalized? 'capitalized-p)
;; Use: (capitalized-p "f") => nil
;; Use: (capitalized-p "Fi") => t
;; Use: (capitalized-p '("a" "b")) => nil
;; Use: (capitalized-p '("a" "B")) => nil

;; ---------------------------------------------------------------------------

(defun region-markedp ()
  "Return non-nil if region is marked."
  (use-region-p))
(defalias 'region-marked? 'region-markedp)

;; auto-capitalize.el --- Automatically capitalize (or upcase) words
(when (require 'auto-capitalize nil t))

(global-set-key [(shift meta c)] 'capitalize-region)

;; fdlcap.el --- Cycle through case and capitalization of words.
(require 'fdlcap nil t)

(provide 'case-utils)
