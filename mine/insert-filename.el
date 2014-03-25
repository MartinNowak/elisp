;; insert-filename.el
;; See: http://www.emacswiki.org/emacs-en/InsertFileName
;; See: Emacs-Lisp Functions containing the pattern "insert-file".

(defun insert-file-name-into-buffer (filename &optional args)
  "Insert name of file FILENAME into buffer after point.
  
  Prefixed with \\[universal-argument], expand the file name to
  its fully canocalized path.  See `expand-file-name'.
  
  Prefixed with \\[negative-argument], use relative path to file
  name from current directory, `default-directory'.  See
  `file-relative-name'.
  
  The default with no prefix is to insert the file name exactly as
  it appears in the minibuffer prompt."
  ;; Based on insert-file in Emacs -- ashawley 20080926
  (interactive "*fInsert file name: \nP")
  (cond ((eq '- args)
         (insert (file-relative-name filename)))
        ((not (null args))
         (insert (expand-file-name filename)))
        (t
         (insert filename))))

(autoload 'ffap-guesser "ffap")
(autoload 'ffap-read-file-or-url "ffap")

(defun replace-file-name-at-point (currfile newfile)
  "Replace CURRFILE at point with NEWFILE.
  
  When interactive, CURRFILE will need to be confirmed by user
  and will need to exist on the file system to be recognized,
  unless it is a URL.
  
  NEWFILE does not need to exist.  However, Emacs's minibuffer
  completion can help if it needs to be.
  
  Based on `ffap'."
  (interactive
   (let ((currfile (ffap-read-file-or-url "Replace filename: "
                                          (ffap-guesser))))
     (list currfile
           (ffap-read-file-or-url (format "Replace `%s' with: "
                                          currfile) currfile))))
  (save-match-data
    (if (or (looking-at (regexp-quote currfile))
            (let ((filelen (length currfile))
                  (opoint (point))
                  (limit (+ (point) (length currfile))))
              (save-excursion
                (goto-char (1- filelen))
                (and (search-forward currfile limit
                                     'noerror)
                     (< (match-beginning 0) opoint))
                (>= (match-end 0) opoint))))
        (replace-match newfile)
      (error "No file at point to replace"))))

;; (global-set-key "\C-c\C-i" 'insert-file-name-into-buffer)
;; (global-set-key "\C-c\C-v" 'replace-file-name-at-point)

(provide 'insert-filename)
