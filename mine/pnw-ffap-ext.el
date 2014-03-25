;; C include path

;; The default ffap-c-path is /usr/include and /usr/local/include, but
;; gcc has a separate directory for bits it provides, like
;; float.h. The following asks gcc for its path. (The output of “gcc
;; -v” isn’t pretty, perhaps there’s a better way to ask.)

(eval-after-load
    (with-temp-buffer
      (when (equal 0 (call-process "gcc" nil t nil
                                   "-v" "-E" "--language=c" "/dev/null"))
        (goto-char (point-min))
        (when (search-forward "#include \"...\" search starts here:" nil t)
          (let (lst)
            (while (re-search-forward "^\\(End of search list\\| \\(.*\\)\\)"
                                      nil t)
              (if (match-beginning 2)
                  (setq lst (cons (match-string 2) lst))
                (goto-char (point-max)))) ;; End
            (when lst
              (setq ffap-c-path (nreverse lst))))))))

;; You can put this in an eval-after-load if you want to defer running
;; gcc until actually firing up ffap.

;; The messages “search starts here” and “End of search list” will
;; be translated in a non-English locale, you might have to adapt
;; them, or force LANG=C for this probe.  C include at start of line

;; This is a little hack to recognise a #include <foo.h> directive
;; when point is anywhere in the line (ffap only otherwise recognises
;; It with point in the <foo.h> part).

(defadvice ffap-string-at-point (around c-include-at-start-of-line activate)
  "Recognise \"#include <foo.h>\" with point at the start of the line."
  (require 'thingatpt)
  (if (thing-at-point-looking-at "#[ \t]*include[ \t]+[\"<]\\([^\">]+\\)[\">]")
      (setq ad-return-value (match-string 1))
    ad-do-it))

(defun create-file-from-region (region &optional filename)
  (interactive "r")
  )
;; (defadvice 'find-file (around c-include-at-start-of-line activate))

;; RFC host

;; In Emacs 21 the default host to download RFC documents is ds.internic.net, but it’s gone away. Emacs 22 has changed to use rfc-editor.org, you can do the same with

(setq ffap-rfc-path "/anonymous@ftp.rfc-editor.org:/in-notes/rfc%s.txt")

;; RFC space

;; A space in an RFC like "RFC 1234" is not matched by ffap (only "RFC1234" or "RFC-1234" or "RFC#1234"). The entry in ffap-alist supports a space, but the guessing in ffap-string-at-point doesn’t match that. You can allow a space with the following spot of code. It adds a (thing-at-point 'rfc) as a bonus and helper (see ThingAtPoint). The regexp is the same as in ffap-alist.

(put 'rfc 'bounds-of-thing-at-point
     (lambda ()
       (and (thing-at-point-looking-at "[Rr][Ff][Cc][- #]?\\([0-9]+\\)")
	    (cons (match-beginning 0) (match-end 0)))))

(defadvice ffap-string-at-point (around rfc-with-space activate)
  (setq ad-return-value (thing-at-point 'rfc))
  (or ad-return-value
      ad-do-it))

;; RFC locally

;; If you keep copies of some RFCs locally then the following spot of code can get ffap to check there first, before offering ffap-rfc-path. The directory /usr/share/doc/RFC/links here is for a Debian system (DebianPackage:doc-rfc-std and friends).

(defvar my-ffap-rfc-locally-list
  '("/usr/share/doc/RFC/links")
  "A list of directories to look for RFC files.")

(defadvice ffap-rfc (around my-ffap-rfc-locally first (name) activate)
  "Look first for a local copy of an RFC using `my-ffap-rfc-locally'."
  (or (setq ad-return-value
	    (save-match-data ;; clobbered by ffap-locate-file
	      (ffap-locate-file (format "rfc%s.txt" (match-string 1 name)) t
				my-ffap-rfc-locally-list)))
      ad-do-it))

(provide 'pnw-ffap-ext.el)
