;;; mthesaur-util.el ---
;; Author: Per Nordlöw

(defun mthesaur-lookup (search-text append-p)
  "Manage the process of searching the thesaurus for SEARCH-TEXT."
  (if (or (null search-text) (string= search-text ""))
      (progn (message "mthesaur -- what word/phrase?") (ding))
    (save-excursion
      (save-selected-window
        (with-temp-message
            (format "Searching Thesaurus for \"%s\", please wait ..."
                    search-text)
          (let ((temp-buf (generate-new-buffer
                           "*Thesaurus Temporary Buffer*")))
            (set-buffer temp-buf)
            (erase-buffer)
            (if (or (mthesaur-first-attempt temp-buf search-text)
                    (mthesaur-second-attempt temp-buf search-text))
                (let ((results-buf (get-buffer-create
                                    "*Thesaurus Search Results*")))
                  (mthesaur-format-results search-text)
                  (mthesaur-display-results append-p temp-buf
                                            results-buf)
                  (shrink-window-if-larger-than-buffer (get-buffer-window results-buf))
                  (message nil))
              (progn (ding)
                     (message
                      "mthesaur -- \"%s\": word/phrase not found."
                      search-text)))
            (kill-buffer temp-buf)))))))

(provide 'mthesaur-util)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; mthesaur-util.el ends here
