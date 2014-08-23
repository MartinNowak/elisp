;;; See: https://stackoverflow.com/questions/14764130/1-of-n-result-for-emacs-search
;;; Authors: Per Nordlöw <per.nordlow@gmail.com>,
;;; Commentary:
;;; Code:
;;; See: https://stackoverflow.com/questions/14764130/1-of-n-result-for-emacs-search

(defun count-search-hits-backward (string &optional bound noerror count)
  (save-excursion
    (let ((count 0))
      (while (ignore-errors (if isearch-regexp
                                (re-search-backward string bound noerror count)
                              (search-backward string bound noerror count)))
        (setq count (1+ count)))
      count)))

(defun count-search-hits-forward (string &optional bound noerror count)
  (save-excursion
    (let ((count 0))
      (while (ignore-errors (if isearch-regexp
                                (re-search-forward string bound noerror count)
                              (search-forward string bound noerror count)))
        (setq count (1+ count)))
      count)))

(defun isearch-count-message ()
  (when isearch-success
   (let* ((string isearch-string))
     (when (>= (length string) 1)
       (let ((before (count-search-hits-backward string))
             (after (count-search-hits-forward string)))
         (setq isearch-message-suffix-add
               (propertize (format " (%d of %d)"
                                   before
                                   (+ before
                                      after))
                           'face 'shadow)))))))

(remove-hook 'isearch-update-post-hook 'isearch-count-message)

;; (when nil
;;   (defun lazy-highlight-cleanup (&optional force)
;;     "Stop lazy highlighting and remove extra highlighting from current buffer.
;; FORCE non-nil means do it whether or not `lazy-highlight-cleanup'
;; is nil.  This function is called when exiting an incremental search if
;; `lazy-highlight-cleanup' is non-nil."
;;     (interactive '(t))
;;     (if (or force lazy-highlight-cleanup)
;;         (while isearch-lazy-highlight-overlays
;;           (delete-overlay (car isearch-lazy-highlight-overlays))
;;           (setq isearch-lazy-highlight-overlays
;;                 (cdr isearch-lazy-highlight-overlays))))
;;     (when isearch-lazy-highlight-timer
;;       (cancel-timer isearch-lazy-highlight-timer)
;;       (setq isearch-message-suffix-add "")
;;       (setq isearch-lazy-highlight-timer nil)))

;;   (defun isearch-lazy-highlight-search ()
;;     "Search ahead for the next or previous match, for lazy highlighting.
;; Attempt to do the search exactly the way the pending Isearch would."
;;     (condition-case nil
;;         (let ((case-fold-search isearch-lazy-highlight-case-fold-search)
;;               (isearch-regexp isearch-lazy-highlight-regexp)
;;               ;; (search-spaces-regexp isearch-lazy-highlight-space-regexp)
;;               (isearch-word isearch-lazy-highlight-word)
;;               (search-invisible nil)    ; don't match invisible text
;;               (retry t)
;;               (success nil)
;;               (isearch-forward isearch-lazy-highlight-forward)
;;               (bound (if isearch-lazy-highlight-forward
;;                          (min (or isearch-lazy-highlight-end-limit (point-max))
;;                               (if isearch-lazy-highlight-wrapped
;;                                   isearch-lazy-highlight-start
;;                                 (isearch-window-end)))
;;                        (max (or isearch-lazy-highlight-start-limit (point-min))
;;                             (if isearch-lazy-highlight-wrapped
;;                                 isearch-lazy-highlight-end
;;                               (isearch-window-start))))))
;;           ;; Use a loop like in `isearch-search'.
;;           (while retry
;;             (setq success (isearch-search-string
;;                            isearch-lazy-highlight-last-string bound t))

;;             ;; Clear RETRY unless the search predicate says
;;             ;; to skip this search hit.
;;             (if (or (not success)
;;                     (= (point) bound)  ; like (bobp) (eobp) in `isearch-search'.
;;                     (= (match-beginning 0) (match-end 0))
;;                     (funcall isearch-filter-predicate
;;                              (match-beginning 0) (match-end 0)))
;;                 (setq retry nil)))
;;           success)
;;       (error nil)))

;;   (defun isearch-find-current-overlay ()
;;     (let ((total 0)
;;           (count 1)
;;           (olist isearch-lazy-highlight-overlays))
;;       (while olist
;;         (setq total (1+ total))
;;         (if (< (overlay-end (car olist)) (point))
;;             (setq count (1+ count)))
;;         (setq olist
;;               (cdr olist)))
;;       (cons count total)))

;;   (defun isearch-window-start ()
;;     "force highlight entire buffer"
;;     (point-min))

;;   (defun isearch-window-end ()
;;     "force highlight entire buffer"
;;     (point-max))

;;   (defun isearch-lazy-highlight-update ()
;;     "Update highlighting of other matches for current search."
;;     (let ((max lazy-highlight-max-at-a-time)
;;           (looping t)
;;           nomore)
;;       (with-local-quit
;;         (save-selected-window
;;           (if (and (window-live-p isearch-lazy-highlight-window)
;;                    (not (eq (selected-window) isearch-lazy-highlight-window)))
;;               (select-window isearch-lazy-highlight-window))
;;           (save-excursion
;;             (save-match-data
;;               (goto-char (if isearch-lazy-highlight-forward
;;                              isearch-lazy-highlight-end
;;                            isearch-lazy-highlight-start))
;;               (while looping
;;                 (let ((found (isearch-lazy-highlight-search)))
;;                   (when max
;;                     (setq max (1- max))
;;                     (if (<= max 0)
;;                         (setq looping nil)))
;;                   (if found
;;                       (let ((mb (match-beginning 0))
;;                             (me (match-end 0)))
;;                         (if (= mb me)   ;zero-length match
;;                             (if isearch-lazy-highlight-forward
;;                                 (if (= mb (if isearch-lazy-highlight-wrapped
;;                                               isearch-lazy-highlight-start
;;                                             (isearch-window-end)))
;;                                     (setq found nil)
;;                                   (forward-char 1))
;;                               (if (= mb (if isearch-lazy-highlight-wrapped
;;                                             isearch-lazy-highlight-end
;;                                           (isearch-window-start)))
;;                                   (setq found nil)
;;                                 (forward-char -1)))

;;                           ;; non-zero-length match
;;                           (let ((ov (make-overlay mb me)))
;;                             (push ov isearch-lazy-highlight-overlays)
;;                             ;; 1000 is higher than ediff's 100+,
;;                             ;; but lower than isearch main overlay's 1001
;;                             (overlay-put ov 'priority 1000)
;;                             (overlay-put ov 'face lazy-highlight-face)
;;                             (overlay-put ov 'window (selected-window))))
;;                         (if isearch-lazy-highlight-forward
;;                             (setq isearch-lazy-highlight-end (point))
;;                           (setq isearch-lazy-highlight-start (point)))))

;;                   ;; not found or zero-length match at the search bound
;;                   (if (not found)
;;                       (if isearch-lazy-highlight-wrapped
;;                           (setq looping nil
;;                                 nomore  t)
;;                         (setq isearch-lazy-highlight-wrapped t)
;;                         (if isearch-lazy-highlight-forward
;;                             (progn
;;                               (setq isearch-lazy-highlight-end (isearch-window-start))
;;                               (goto-char (max (or isearch-lazy-highlight-start-limit (point-min))
;;                                               (isearch-window-start))))
;;                           (setq isearch-lazy-highlight-start (isearch-window-end))
;;                           (goto-char (min (or isearch-lazy-highlight-end-limit (point-max))
;;                                           (isearch-window-end))))))))
;;               (unless nomore
;;                 (setq isearch-lazy-highlight-timer
;;                       (run-at-time lazy-highlight-interval nil
;;                                    'isearch-lazy-highlight-update)))))))))
;;   )
(provide 'indexed-isearch)
;;; indexed-isearch.el ends here
