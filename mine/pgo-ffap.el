;;; pgo-ffap.el --- Setup Find File At Point (ffap).
;; Author: Per Nordlöw

(require 'ffap- nil t)

(when nil
  (eval-after-load "ffap" '(require 'ffap-include-start)) ;See: http://groups.google.com/group/gnu.emacs.sources/browse_thread/thread/462c81b5750ca978#
  (eval-after-load "ffap" '(require 'ffap-href))
  (eval-after-load "ffap" '(require 'ffap-gcc-path)) ;get gcc's include path for ffap-c-path
  (eval-after-load "ffap" '(require 'ffap-makefile-vars)) ;makefile variables expanded
  (eval-after-load "ffap" '(require 'ffap-mml)) ;find Gnus message MML attached file at point
  (eval-after-load "ffap" '(require 'ffap-perl-module)) ;find perl module at point with ffap
  (eval-after-load "ffap" '(require 'ffap-rfc-space)) ;recognise RFC with a space, like "RFC 1234"
  (autoload 'ffap-pod-F-enable "ffap-pod-F" nil t)
  (eval-after-load "ffap" '(ffap-pod-F-enable)) ;follow Perl pod F<filename>
  (autoload 'ffap-href-enable "ffap-href" nil t)
  (eval-after-load "ffap" '(require 'ffap-href))
  ;; "<a href" is HTML-specific but `ffap-href-enable' applies it globally since it shouldn't clash with anything else.
  (eval-after-load "ffap" '(ffap-href-enable)))
;; (require 'pnw-ffap-ext nil t)
;;; Go to the indicated line with `find-file-at-point'
(when nil
  (defadvice find-file-at-point (around goto-line compile activate)
    (let ((line (and (looking-at ".*:\\([0-9]+\\)")
		     (parse-integer (match-string 1)))))
      ad-do-it
      (and line (goto-line line))))
  (ad-activate 'find-file-at-point)
  )

(defadvice find-file-at-point (after propose-active-mark activate)
  (when (and (called-interactively-p 'any)
             (use-region-p))
    (find-file (buffer-substring (region-beginning)
                                 (region-end)))))
(ad-activate 'find-file-at-point)

(provide 'pgo-ffap)
