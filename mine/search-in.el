;;; search-in.el --- Contextual String and Regexp Search.
;; Author: Per Nordlöw
;; Created: tis nov  3 10:09:06 2009 (+0100)

;; TODO Add these as modes in `isearch-mode-map' and `query-replace-map'.
(defun search-in-syntax-code (forward string &optional bound noerror count)
  "Search for STRING outside comments and strings.
FORWARD non-nil means search forward, else search backwards.  See
`search-forward' for doc on rest arguments."
  (let ((function (if forward 'search-forward 'search-backward))
	(start (point)))
    (if (and (funcall function string bound noerror count)
	     (not (save-match-data (syntax-ppss-context (syntax-ppss)))))
	(match-beginning 0)
      (or (catch 'found
	    (while (funcall function string bound noerror count)
	      (if (not (eq 'comment
			   (syntax-ppss-context (save-match-data
						  (syntax-ppss)))))
		  (throw 'found
			 (if forward (match-end 0) (match-beginning 0)))
		(if forward
		    (unless (eobp) (forward-char))
		  (unless (bobp) (backward-char))))))
	  (progn (goto-char start)
		 nil)))))
(defalias 'search-in-code 'search-in-syntax-code)

(defun search-forward-in-syntax-code (string &optional bound noerror count)
  (search-in-syntax-code t string bound noerror count))
(defun search-backward-in-syntax-code (string &optional bound noerror count)
  (search-in-syntax-code nil string bound noerror count))

(defun re-search-in-syntax-code (forward regex &optional bound noerror count)
  "Search for REGEX outside comments and strings.
FORWARD non-nil means search forward, else search backwards.  See
`re-search-forward' for doc on rest arguments."
  (let ((function (if forward 're-search-forward 're-search-backward))
	(start (point)))
    (if (and (funcall function regex bound noerror count)
	     (not (save-match-data (syntax-ppss-context (syntax-ppss)))))
	(match-beginning 0)
      (or (catch 'found
	    (while (funcall function regex bound noerror count)
	      (if (not (eq 'comment
			   (syntax-ppss-context (save-match-data
						  (syntax-ppss)))))
		  (throw 'found
			 (if forward (match-end 0) (match-beginning 0)))
		(if forward
		    (unless (eobp) (forward-char))
		  (unless (bobp) (backward-char))))))
	  (progn (goto-char start)
		 nil)))))
(defalias 're-search-in-code 're-search-in-syntax-code)

(defun re-search-forward-in-syntax-code (string &optional bound noerror count)
  (re-search-in-syntax-code t string bound noerror count))
(defun re-search-backward-in-syntax-code (string &optional bound noerror count)
  (re-search-in-syntax-code nil string bound noerror count))

(provide 'search-in)
