;;; pgo-browse-url.el --- Setup browse-url.el.

;;; http://www.emacswiki.org/cgi-bin/wiki/BrowseAproposURL
;;; browse-url.el --- pass a URL to a WWW browser

(setq apropos-url-alist
      '(
        ;; Google Web
        ("^gw?:? +\\(.*\\)" .
         "http://www.google.com/search?q=\\1")

        ;; Google Lucky
        ("^g!:? +\\(.*\\)" .
         "http://www.google.com/search?btnI=I%27m+Feeling+Lucky&q=\\1")

        ;; Google Linux
        ("^gl:? +\\(.*\\)" .
         "http://www.google.com/linux?q=\\1")

        ;; Google Images
        ("^gi:? +\\(.*\\)" .
         "http://images.google.com/images?sa=N&tab=wi&q=\\1")

        ;; Google Groups
        ("^gg:? +\\(.*\\)" .
         "http://groups.google.com/groups?q=\\1")

        ;; Google Directory
        ("^gd:? +\\(.*\\)" .
         "http://www.google.com/search?&sa=N&cat=gwd/Top&tab=gd&q=\\1")

        ;; Google News
        ("^gn:? +\\(.*\\)" .
         "http://news.google.com/news?sa=N&tab=dn&q=\\1")

        ;; Google Translate URL
        ("^gt:? +\\(\\w+\\)|? *\\(\\w+\\) +\\(\\w+://.*\\)" .
         "http://translate.google.com/translate?langpair=\\1|\\2&u=\\3")

        ;; Google Translate Text
        ("^gt:? +\\(\\w+\\)|? *\\(\\w+\\) +\\(.*\\)" .
         "http://translate.google.com/translate_t?langpair=\\1|\\2&text=\\3")

        ;; Slashdot
        ("^/\\.$" .
         "http://www.slashdot.org")

        ;; Slashdot search
        ("^/\\.:? +\\(.*\\)" .
         "http://www.osdn.com/osdnsearch.pl?site=Slashdot&query=\\1")

        ;; Freshmeat
        ("^fm$" .
         "http://www.freshmeat.net")

        ;; Emacs Wiki Search
        ("^ewiki:? +\\(.*\\)" .
         "http://www.emacswiki.org/cgi-bin/wiki?search=\\1")

        ;; Emacs Wiki
        ("^ewiki$" .
         "http://www.emacswiki.org")

        ;; The Encyclopedia of Arda
        ("^arda$" .
         "http://www.glyphweb.com/arda/")
        ))

;; Don't know if it's the best way , but it seemed to work.
(defun browse-apropos-url (text &optional new-window)
  (interactive (browse-url-interactive-arg "Location: "))
  (let ((text (replace-regexp-in-string
               "^ *\\| *$" ""
               (replace-regexp-in-string "[ \t\n]+" " " text))))
    (let ((url (assoc-default
                text apropos-url-alist
                (lambda (a b) (let () (setq __braplast a) (string-match a b)))
                text)))
      (browse-url (replace-regexp-in-string
                   __braplast url text) new-window))))

;; Now, if you are reading a spanish text and wondering what a
;; sentence means. Just mark the sentence and do the following:
;;   M-x browse-apropos-url-on-region RET gt es en RET
;; This will append the region content to "gt es en " and use your
;; browser to let google do the hard work.
(defun browse-apropos-url-on-region (min max text &optional new-window)
  (interactive "r \nsAppend region to location: \nP")
  (browse-apropos-url (concat text " "
                              (buffer-substring min max)) new-window))

(when nil
  (when (require 'browse-url nil t)
    ;;(setq browse-url-browser-function 'browse-url-firefox)
    (setq browse-url-browser-function 'browse-url-generic
          browse-url-generic-program "chromium-browser")

    (defcustom browse-url-chromium-program "chromium"
      "The name by which to invoke Chromium."
      :type 'string
      :group 'browse-url)

    (defcustom browse-url-chromium-arguments nil
      "A list of strings to pass to Chromium as arguments."
      :type '(repeat (string :tag "Argument"))
      :group 'browse-url)

    (defcustom browse-url-chromium-startup-arguments browse-url-chromium-arguments
      "A list of strings to pass to Chromium when it starts up.
Defaults to the value of `browse-url-chromium-arguments' at the time
`browse-url' is loaded."
      :type '(repeat (string :tag "Argument"))
      :group 'browse-url)

    (defun browse-url-chromium-sentinel (process url)
      "Handle a change to the process communicating with Chromium."
      (or (eq (process-exit-status process) 0)
          (let* ((process-environment (browse-url-process-environment)))
            ;; Chromium is not running - start it
            (message "Starting %s..." browse-url-chromium-program)
            (apply 'start-process (concat "chromium " url) nil
                   browse-url-chromium-program
                   (append browse-url-chromium-startup-arguments (list url))))))

    ;; (if (executable-find "chromium-browser")
    ;;     (setq browser-url-browser-function "chromium-browser")
    ;;   (if (executable-find "firefox-3.5")
    ;;       (setq browser-url-browser-function "firefox-3.5")
    ;;     (if (executable-find "firefox")
    ;;         (setq browser-url-browser-function "firefox"))))
    )

  )

(provide 'browse-apropos-url)
