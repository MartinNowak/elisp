;;; tscan.el --- (File System) Tree Scan and Query-Operate.
;;;
;;; Operations are typically search and replace. Integrates tightly with
;;; `fcache' and `filedb'.
;;;
;;; Unifies the UNIX tools `grep', `file', `find', `string', `tree', `du',
;;; `objdump' with the Emacs tools `findr', `occur' `tags-query-replace' and
;;; `vc-dir' to work on multi-platform out of the box without any
;;; dependencies on external command line tools. "On tool to rule them all"!
;;
;; Copyright (C) 2011 Per Nordlöw
;; Author: Per Nordlöw <per.nordlow@gmail.com>
;;
;; TODO: Sort and Display Extended Attributes when they are supported by the filesystem
;; TODO: Sort symlinks on destination-mod-time.
;; TODO: v/V-U,M,S: Next/Previous Up-to-date/Modified,Same.
;;
;; TODO: Sort Files/Dirs on Mod-Time before accessing them.
;;
;; TODO: Make use of `word-search-.*' instead of regexp search.
;;
;; TODO: Prune directory tree branches with no hits. Is this info already in the hit-tree?
;; TODO: Cluster Function Calls on Argument Count. Especially in `cc-derived-mode-p' using structed.el and `c-arg-count'.
;; TODO: Add colored hit-count-indicator to mode-line upon scan completion: TScan:#12, grey if no hits, green if any hits. Search for mode-line for details.
;;
;; TODO: Use maphash variant of `dotimes-with-progress-reporter' when scanning files in using maphash.
;; TODO: Toggle Cluster Locality: File, Directory, Tree
;; TODO: Select Cluster Sorting Order:
;; TODO: Colorize skipped dirs in darker more passive color instead of red overstrike.
;; TODO: Bug: Searching for `vc-git-dir-status-files' in vc-git.el.gz under "tscan-tests" gives no hits!
;; TODO: Divide scan into directories using run-with-idle-timer.
;; TODO: Use fcache relations last target using `file-chase-links'. Use this
;;       fcache instead of `file-directory-p' and `file-executable-p' in
;;       `tscan-directory'.
;;
;; TODO: Prune sub-dirs with no filename or contents hits
;; TODO: *Query-Replace* first opens literally to scan if there any hits at all
;; and only if there are it again opens the buffer normally to query the
;; replaces.
;;
;; TODO: Add mode-local clustering:
;; - emacs-lisp-mode
;;   - Function: "(buffer-file-name)"
;;   - Symbol: "'buffer-file-name"
;;   - Symbol Value: "buffer-file-name"
;;
;; TODO: Colorize Hit Cluster Backgrounds:
;; - Textual File: (Black)
;; - Binary  File: (DarkGrey signifies less significant) filea
;;
;; TODO: Skip Clustering Context for regexps like \_<int\_>
;;
;; TODO: Enable `vc-sort' when we there is a function say `vc-state-directory'.
;;       Try M-x find-library RET vc RET and then look for dir-status in the
;;       comment/doc at the beginning of the file for the "full" story. Use:
;;       - (let ((default-directory "~/cognia/")) (vc-git-command nil 'async "." "status" "-s") (display-buffer "*vc*"))
;;         - "A " 'added (created)
;;         - "M " 'edited (modified)
;;         - " R" 'renamed
;;         - " C" 'copied
;;         - " D" 'removed (deleted)
;;         - "??" 'unregistered (untracked)
;;       - (let ((default-directory (elsub "mine/tscan-tests/bzr-test/"))) (vc-bzr-command "status" nil 'async "." "-S") (display-buffer "*vc*"))
;;       Store in `fcache' using aset(fcache fcache-fi-vc-state intern('unregistered)) or aset(fcache fcache-fi-vc-state 'unregistered).
;;       See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/9e0a6e5170e9f48b
;;
;; TODO: Sort on Symbol-Context (s c):
;;       - Symbol
;;       - Word
;;         - Prefix
;;         - Suffix
;;       - In-Word
;;
;; TODO: Sort on Syntax-Context:
;;       - Variables
;;         - Initialization
;;         - Assignment: (when (cc-derived-mode-p) `c-op-assignment')
;;         - Reference
;;       - Functions
;;       - Declaration
;;       - Definition
;;       - Call
;;       - Reference (Pointer)
;;
;; TODO: Group (Interface/Implementation) Header-Source Pairs (C,C++,Objective-C)
;;
;; TODO: Sort on File-Type
;;       - Files with Hits (Sort Descending on # Hits)
;;       - Language Type (C, C++, etc.)
;;       - Name Format (Context)
;;       - Editable Files: No Hits
;;       - Uneditable Files:
;;       - Cluster: after Context Word/Symbol Names; atomic_read32, atomic_inc32, atomic_cas32 in separate Clusters.
;;       - Directories: Start with smallest or fewest files.
;;
;; TODO: Sort on File VC-State - `vc-sort' should order like:
;;       - Modified
;;       - New (unregistered)
;;       - Up-to-Date
;;       - Ignored
;;
;; TODO: Fuzzy Clustering by treating '-', '_', and ' ' as similar.
;;
;; TODO: Remove empty clusters (tree branches) in `cscan' by nulling and handle
;; this case in `tscan' to gain some memory.
;;
;; TODO: Highlight sub-hit-index by number: blue, green, red, yellow, orange, cyan, magenta
;;
;; TODO: Add TRAMP prefix when opening unreadable files or directories because
;; they are not accessible by current user. Use `file-readable-p', `fcache-readable' and
;; `file-accessible-directory-p'.
;;
;; TODO: Upon file modification can we detect what region that changed and only
;; update the hits that overlap this region?
;;
;; TODO: Propose to relax matching expression if no hits were found. Also add
;;       this state in the menu. Relaxation types:
;;       - intra-token whitespace.
;;       - intra-char space: "abc" => "a.b.c"
;;
;; TODO: Merge with tree-buffer.el or tree-mode.el
;; TODO: Find all hits on the same line for the `cluster' case of `cscan-buffer'.
;;
;; TODO: Can we make Directory/File/Hit Button actions a function that takes fcache and range as arguments?
;; TODO: RET: If on directory button call tscan in that directory. This ask to scan as root using TRAMP
;; TODO: "f n/p": next/previous file
;; TODO: "d n/p": next/previous directory
;; TODO: "F n/p": next/previous filename hit
;; TODO: "D n/p": next/previous dirname hit
;; TODO: "c n/p": next/previous file content hit
;; TODO: "n n/p": next/previous file name hit
;; TODO: "c n/p": next/previous cluster (group)
;;
;; TODO: Add Tags to View.
;;
;; TODO: Support Time-Based Clustering of Values
;; TODO: Merge ideas with `anything-grep.el'. See `anything.pdf'.
;; TODO: Replace use of `tscan-file-links-string' with `tscan-fcache-links-string'.
;;
;; TODO: Support options with widgets: http://www.dina.kvl.dk/~abraham/custom/widget.html
;;       - Use hide-region.el to hide Groups of Uneditable files.
;;       - Show All Hits (in binary and uneditable files).

(require 'file-utils)
(require 'filedb)
(require 'power-utils)
(require 'multi-read)
(require 'hash-table-utils)
(require 'obarray-utils)
(require 'elp)
(require 'hictx)
(require 'repeatable)
(require 'case-utils)
(require 'vc-states)
(require 'vc-roots)
(require 'diredp nil t)

;; ============================================================================

(defgroup tscan nil
  "(File System) Tree Scan and Operate (Query Replace/Apply-Macro/Delete File)."
  :group 'tools)

(defvar tscan-root nil
  "Current Diretory TScan is scanning under.")
(make-variable-buffer-local 'tscan-root)

(defvar tscan-pattern nil
  "Current String TScan is scanning for.")
(make-variable-buffer-local 'tscan-pattern)

(defvar tscan-regexp-flag nil
  "Flags that TScan is scanning using regexp instead of string.")
(make-variable-buffer-local 'tscan-regexp-flag)

(defvar tscan-error-pos nil)
(make-variable-buffer-local 'tscan-error-pos)

(defvar tscan-total-hit-count nil
  "TScan Total Hit Count.")
(make-variable-buffer-local 'tscan-total-hit-count)

(defvar tscan-mode-map nil
  "Keymap used in Tree-Scan (TScan) mode.")
(setq tscan-mode-map
      (let ((map (make-sparse-keymap))
            ;;(menu-map (make-sparse-keymap))
            )
        (define-key map [(?<)] 'tscan-first-node)
        (define-key map [(?>)] 'tscan-last-node)

        (define-key map [(?p)] 'tscan-previous-node)
        (define-key map [(?n)] 'tscan-next-node)

        (define-key map "\M-\t" 'tscan-previous-node)
        (define-key map    "\t" 'tscan-next-node)

        (define-key map [(meta ?p)] 'tscan-previous-node-display)
        (define-key map [(meta ?n)] 'tscan-next-node-display)

        (define-key map [(?d)] 'tscan-next-dir)
        (define-key map [(?D)] 'tscan-previous-dir)

        (define-key map [(?f)] 'tscan-next-file)
        (define-key map [(?F)] 'tscan-previous-file)

        (define-key map [(?l)] 'tscan-next-symlink)
        (define-key map [(?L)] 'tscan-previous-symlink)

        (define-key map [(?c)] 'tscan-next-cluster)
        (define-key map [(?C)] 'tscan-previous-cluster)

        (define-key map [(?h)] 'tscan-next-hit)
        (define-key map [(?H)] 'tscan-previous-hit)

        ;; Note: Disabled, because it should be supported by global key-bindings.
        ;; (define-key map [(f8)] 'tscan-next-hit)
        ;; (define-key map [(f7)] 'tscan-previous-hit)

        (define-key map [(?s)] 'tscan-search)
        (define-key map [(?g)] 'tscan-restart)
        (define-key map [(?q)] 'tscan-quit)
        (define-key map [(?k)] 'tscan-kill)

        (define-key map [(?m)] 'tscan-mark-node)
        (define-key map [(?u)] 'tscan-unmark-node)

        (define-key map [(?R)] 'tscan-rename-node)
        (define-key map [(control ?d)] 'tscan-delete-node)

        (define-key map [(?\()] 'tscan-start-macro)
        (define-key map [(\))] 'tscan-end-or-call-macro)

        map))

(defconst tscan-menu-list
  '("TScan"
    ["First" tscan-first-node t]
    ["Last" tscan-last-node t]

    ["Previous Node" tscan-previous-node t]
    ["Next Node" tscan-next-node t]

    ["Previous Node (Display)" tscan-previous-node-display t]
    ["Next Node (Display)" tscan-next-node-display t]

    ["Previous Directory" tscan-previous-dir t]
    ["Next Directory" tscan-next-dir t]

    ["Previous File" tscan-previous-file t]
    ["Next File" tscan-next-file t]

    ["Previous Sym-Link" tscan-previous-symlink t]
    ["Next Sym-Link" tscan-next-symlink t]

    ["Previous Cluster (group of hits)" tscan-previous-cluster t]
    ["Next Cluster (group of hits)" tscan-next-cluster t]

    ["Previous Hit" tscan-previous-hit t]
    ["Next Hit" tscan-next-hit t]

    ["New Search in Tree" tscan-search t]
    ["Rescan same Tree" tscan-restart t]

    ["Mark Node" tscan-mark-node t]
    ["Unmark Node" tscan-unmark-node t]

    ["Rename Node" tscan-rename-node t]

    ["Start Macro" tscan-start-macro t]
    ["End or Call Macro" tscan-end-or-call-macro t]
    )
  "Menu Stubs in C/C++ mode.")

(add-hook 'tscan-mode-hook (lambda () (easy-menu-define tscan-menu tscan-mode-map "TScan Menu" tscan-menu-list)) t)

(define-derived-mode tscan-mode fundamental-mode "TScan"
  "Minor mode for File System Tree Scans."
  (use-local-map tscan-mode-map)
  (make-local-variable 'tscan-root)
  (make-local-variable 'tscan-pattern)
  (make-local-variable 'tscan-regexp-flag)
  (setq next-error-function 'tscan-next-error-function
        tscan-error-pos nil)
  )

;; ---------------------------------------------------------------------------

(defvar tscan-vc-sort nil
  "Flags that TScan results should be sorted on VC state.")

(defun fcache-mtime-lessp (a b)
  (> (fcache-mtime a)
     (fcache-mtime b)))

(defun fcache-tscan-sub-lessp (a b)
  "Compare the two file caches A and B in a way suitable for
presentation."
  ;; - VC-State
  ;; (and tscan-vc-sort
  ;;      (let ((a-vcs (fcache-vc-state-cached a))
  ;;            (b-vcs (fcache-vc-state-cached b)))
  ;;        (string< (symbol-name a-vcs)
  ;;                 (symbol-name b-vcs))))
  ;; - Filetype
  (let ((a-reg (fcache-regular-p a))
        (b-reg (fcache-regular-p b)))
    (if (eq a-reg b-reg)            ;if either both regular files or directories
        (let ((a-ed (file-editable-p a))
              (b-ed (file-editable-p b)))
          (if (eq a-ed b-ed)
              ;; - Access Time
              (let ((a-atime (fcache-mtime a))
                    (b-atime (fcache-mtime b)))
                (if (= a-atime b-atime)
                    (let ( ;; (a-full (fcache-full-fname a))
                          ;; (b-full (fcache-full-fname b))
                          )
                      ;; - Editability
                      (let ( ;; (a-uned (file-uneditable-p a-full))
                            ;; (b-uned (file-uneditable-p b-full))
                            )
                        (let ((a-name (fcache-full-fname a))
                              (b-name (fcache-full-fname b)))
                          ;; - File Name Extension
                          (let ((a-ext (file-name-extension a-name))
                                (b-ext (file-name-extension b-name)))
                            (if (string= a-ext b-ext)
                                ;; - Base Name
                                (let ((a-base (file-name-sans-extension a-name))
                                      (b-base (file-name-sans-extension b-name)))
                                  (string< a-base b-base))
                              (string< a-ext b-ext))))))
                  (> a-atime b-atime)))
            a-ed
            ))
      a-reg                             ;file first, directory second
      )))

;; ---------------------------------------------------------------------------

(defvar tscan-last-dir nil
  "Directory in which current cluster scan is being performed.")

(defvar tscan-buffer-history nil
  "History of TScan buffers.")

(defun tscan-buffer ()
  "Return buffer where the hits of the current/Recent TScan are displayed."
  (setq tscan-buffer-history
        (remove-if-not 'buffer-live-p tscan-buffer-history))
  (car tscan-buffer-history))
(defun tscan-current-buffer ()
  "Return Current TScan Buffer."
  (if (eq major-mode 'tscan-mode)
      (current-buffer)
    (tscan-buffer)))

(defvar tscan-timer nil)
(defvar tscan-buffer-prefix "tscan")
;; Note: (set-buffer (get-buffer "*Messages*"))

(defconst tscan-attr-face-size 0.7)     ;Use 0.7 or 1.0

(defcustom tscan-align-hits-flag t
  "Non-nil if TScan hits should be aligned."
  :group 'tscan)

(defface tscan-file-type-face
  `((((class color)) (:inherit font-lock-type-face :italic t :height ,tscan-attr-face-size)))
  "Hit Type Face."
  :group 'tscan)
(defface tscan-file-size-face
  '((((class color)) (:inherit font-lock-number-face :height 1.0)))
  "File Size Face."
  :group 'tscan)

(defface tscan-hit-attr-face
  `((((class color)) (:inherit font-lock-comment-face :italic t :height ,tscan-attr-face-size)))
  "Hit Attribute Face."
  :group 'tscan)

(defface tscan-hit-directory-face
  '((((class color)) (:inherit font-lock-directory-name-face)))
  "Entered Directory Face."
  :group 'tscan)

;; Skipped/Uneditable Files
(defface tscan-skipped-file-face
  '((((class color)) (:inherit font-lock-file-name-face :strike-through "red")))
  "Skipped File Face."
  :group 'tscan)
(defface tscan-skipped-directory-face
  '((((class color)) (:inherit font-lock-directory-name-face :strike-through "red")))
  "Skipped Directory Face."
  :group 'tscan)
(defface tscan-uneditable-file-face
  `((((class color)) (:inherit ,(if (facep 'diredp-ignored-file-name)
                                    'diredp-ignored-file-name
                                  'shadow))))
  "Uneditable File Face."
  :group 'tscan)

(defface tscan-hit-file-face
  '((((class color)) (:inherit font-lock-file-name-face)))
  "Hit File Face."
  :group 'tscan)
(defface tscan-hit-count-face
  `((((class color)) (:inherit font-lock-number-face :height ,tscan-attr-face-size)))
  "Hit File Face."
  :group 'tscan)

(defface tscan-symlink-file-face
  '((((class color)) (:inherit font-lock-file-name-face :slant italic)))
  "Symbolic Link File."
  :group 'tscan)

;; Unreadable Files
(defface tscan-unreadable-file-face
  '((((class color)) (:inherit font-lock-file-name-face :strike-through "orange")))
  "Unreadable File Face."
  :group 'tscan)
(defface tscan-unreadable-directory-face
  '((((class color)) (:inherit font-lock-directory-name-face :strike-through "orange")))
  "Unreadable Directory Face."
  :group 'tscan)
(defface tscan-unreadable-symlink-file-face
  '((((class color)) (:inherit tscan-symlink-file-face :strike-through "orange")))
  "Unreadable File Face."
  :group 'tscan)

(defface tscan-symlink-target-face
  '((((class color)) (:inherit font-lock-file-name-face)))
  "Symbolic Link Target Face."
  :group 'tscan)

(defface tscan-symlink-missing-target-face
  '((((class color)
      (background light))
     (:foreground "grey80"))
    (((class color)
      (background dark))
     (:foreground "grey30")))
  "Symbolic Link Missing Target Face."
  :group 'tscan)

(defface tscan-fs-conn-face
  '((((class color)) (:inherit font-lock-file-name-face)))
  "File System Connection Face."
  :group 'tscan)

(defface tscan-cluster-name-face
  `((((class color)
      (background dark))
     (:inherit font-lock-type-face :slant italic :height ,tscan-attr-face-size :foreground "#707030")))
  "Cluster Name Face."
  :group 'tscan)

(defface tscan-hit-delim-face
  '((((class color)
      (background dark))
     (:underline nil :foreground "black" :background "grey60")))
  "File Name or Content Hit Delimitation Face."
  :group 'tscan)

(defface tscan-hit-face
  '((((class color)) (:inherit next-error)))
  "File Name or Content Hit Face."
  :group 'tscan)

;; Note: Borrowe from git-ignored-face
(defface tscan-bin-hit-face
  '((((class color)
      (background light))
     (:foreground "grey60"))
    (((class color)
      (background dark))
     (:foreground "grey40")))
  "tscan file content binary hits."
  :group 'tscan)

;; ---------------------------------------------------------------------------

(defun tscan-display-target-buffer (buffer &optional noselect)
  "Display TScan target BUFFER."
  (if (eq (window-buffer (selected-window))
          (tscan-buffer))
      ;; If the tscan buffer window was selected,
      ;; keep the tscan buffer in this window;
      ;; display the source in another window.
      (let ((pop-up-windows t))
        (display-buffer buffer t)       ;(pop-to-buffer buffer 'other-window)
        )
    (switch-to-buffer buffer)
    ;; (unless noselect
    ;;   (switch-to-buffer buffer))
    ))

(defun tscan-display-target-file (filename &optional pos noselect)
  "Display target file FILENAME at position POS in a another window.
If NOSELECT is non-nil don't select the other window.
Return buffer of FILENAME."
  (let* ((buffer (find-file-noselect filename)))
    (tscan-display-target-buffer buffer noselect)
    (let ((window (get-buffer-window buffer)))
      (unless noselect
        (select-window window))
      (when pos
        (set-window-point window pos))) ;move point in target buffer
    buffer))

(defun tscan-display-target-fcache (fcache &optional pos noselect)
  "Display hit target fcache at file position POS in a another window.
If NOSELECT is non-nil don't select the other window."
  (tscan-display-target-file (fcache-full-fname fcache) pos noselect))

;; ---------------------------------------------------------------------------

(define-button-type 'tscan-dir-button
  'follow-link t
  'action 'tscan-dir-action
  'help-echo "mouse-2, RET: Jump to TScan directory.")

(defun tscan-dir-action (button)
  (let* ((fcache (button-get button 'target)))
    (when fcache (tscan-display-target-fcache fcache))
    ))

;; ---------------------------------------------------------------------------

(define-button-type 'tscan-file-button
  'follow-link t
  'action 'tscan-file-action
  'help-echo "mouse-2, RET: Jump to TScan file.")

(define-button-type 'tscan-bin-file-button
  'follow-link t
  'action 'tscan-file-action
  'help-echo "mouse-2, RET: Jump to TScan binary file.")

(defun tscan-file-action (button)
  (let* ((fcache (button-get button 'target)))
    (when fcache (tscan-display-target-fcache fcache))
    ))

;; ---------------------------------------------------------------------------

(defvar tscan-flash-timer nil
  "Timer for flashing of TScan hit (context) .")

(defun tscan-flash-button (&optional button window)
  "Flash BUTTON optionally in window WINDOW."
  (hictx-generic (button-start button)
                 (button-end button)
                 window nil 0.2))

(defun tscan-flash-target (&optional start end window)
  (when tscan-flash-timer            ;if previous flash timer
    (cancel-timer tscan-flash-timer)      ;cancel it
    (setq tscan-flash-timer nil))
  (let ((face 'next-error)
        (duration 0.35))
    ;;(hictx-line window face duration)
    (hictx-generic start end window face duration nil)
    ))

;; ---------------------------------------------------------------------------

(define-button-type 'tscan-hit-button
  'face 'default ;note: skip underlining because it clutters up presentation!
  'follow-link t
  'action 'tscan-hit-action
  'help-echo "mouse-2, RET: Jump to TScan file contents search hit.")

(defun tscan-hit-action (button)
  (let* ((target (button-get button 'target))
         (fcache (car target))
         (start (cadr target))
         (end (caddr target)))
    (when fcache
      (let ((window (get-buffer-window (tscan-display-target-fcache fcache start))))
        (tscan-flash-target start end window)
        ))))

(defun tscan-present-target-file (filename &optional start end noselect)
  (unless (file-exists-p filename)
    (error "Argument FILENAME is not a file!"))
  (when (and filename (not (file-directory-p filename)))
    (let ((old-buffer (current-buffer)))
      (let ((window (get-buffer-window (tscan-display-target-file filename start noselect))))
        (tscan-flash-target start end window))
      (set-buffer old-buffer))))

(defun tscan-present-target (button &optional noselect)
  "Display `target' of `button' in other window."
  (let ((target (button-get button 'target)))
    (cond ((stringp target)             ;FILENAME
           (tscan-present-target-file target nil nil noselect))
          ((fcachep target)             ;FCACHE
           (let* ((fcache target)
                  (filename (fcache-full-fname fcache)))
             (tscan-present-target-file filename nil nil noselect)))
          ((and (listp target)          ;(FCACHE START END)
                (fcachep (car target)))
           (let* ((fcache (car target))
                  (filename (fcache-full-fname fcache))
                  (start (cadr target))
                  (end (caddr target)))
             (tscan-present-target-file filename start end noselect))))))

(defun tscan-display-button-target (&optional button noselect)
  "Display `target' of BUTTON.
BUTTON defaults to button at `point'."
  (unless button (setq button (button-at (point))))
  (when button
    (tscan-present-target button noselect)))

(defun tscan-button-act (button &optional buffer display)
  "Act on BUTTON in TScan Buffer BUFFER.
BUFFER defaults to (current-buffer).
If DISPLAY is non-nil display target hit aswell.
If DISPLAY is equal to 'select select target window aswell."
  (let ((window (get-buffer-window buffer))
        (start (button-start button)))
    (set-window-point window start)     ;change TScan buffer position
    (tscan-flash-button button window)
    (when display
      (tscan-display-button-target button (if (eq display 'select)
                                              nil
                                            t)))))

;; ============================================================================

(defconst tscan-base-prefix "├─ ")
(defconst tscan-base-prefix-length (length tscan-base-prefix))

(defconst tscan-in-prefix "│  ")

(defconst tscan-last-prefix "└─ ")
(defconst tscan-hit-prefix "│")

(defconst tscan-cluster-prefix "├")
(defconst tscan-last-cluster-prefix "└")
(defconst tscan-cluster-prefix-length (length tscan-cluster-prefix))
(defconst tscan-symlink-follow "->")

;; ---------------------------------------------------------------------------

(defun tscan-ding (format-string &optional position)
  "Restore stuff optionally to POSITION and ding FORMAT-STRING."
  (when position                        ;if given
    (goto-char position))               ;restore things
  (message format-string)
  (ding))

;; ---------------------------------------------------------------------------

(defun tscan-fcache-target-face (fcache)
  (cond ((fcache-regular-p fcache)
         'tscan-hit-file-face)
        ((fcache-symlink-p fcache)
         'tscan-symlink-file-face)
        ((fcache-directory-p fcache)
         'tscan-hit-directory-face)
        ('tscan-hit-file-face)
        ))

(defun tscan-button-target-name (button name-face)
  "Return BUTTON target name (URL)."
  (let* ((target (button-get button 'target)))
    (cond ((stringp target)             ;FILENAME
           target)
          ((fcachep target)             ;FCACHE
           (propertize (abbreviate-file-name (fcache-full-fname target))
                       'face (or name-face (tscan-fcache-target-face target))))
          ((and (listp target)          ;(FCACHE START END)
                (fcachep (car target)))
           (concat
            (let ((fcache (car target)))
              (propertize (abbreviate-file-name (fcache-full-fname fcache))
                          'face (or name-face (tscan-fcache-target-face fcache))))
            ":[" (number-to-string (second target))
            "," (number-to-string (third target)) "]"))
          (target)
          )))

;; ---------------------------------------------------------------------------

(defun tscan-next-button (&optional pos display type error-message ok-message name-face)
  "Move point to next button of type TYPE after position POS in the current TScan buffer."
  (interactive)
  (with-current-buffer (tscan-current-buffer)
    (let (button)
      (if (catch 'hit
            (save-excursion
             (while (setq button (next-button (or pos (point))))
               (when (or (null type)     ;either any kind of button
                         (eq (button-type button) type)) ;if dir button
                 (throw 'hit button))
               (goto-char (button-start button)))))
          (progn
            (message (concat (or ok-message "Next button") ": "
                             (tscan-button-target-name button name-face)))
            (tscan-button-act button (current-buffer) display))
        (tscan-ding (or error-message "No next button"))))))
(repeatable-command-advice tscan-next-button)

(defun tscan-previous-button (&optional pos display type error-message ok-message name-face)
  "Move point to previous button of type TYPE after position POS in the current TScan buffer."
  (interactive)
  (with-current-buffer (tscan-current-buffer)
    (let (button)
      (if (catch 'hit
            (save-excursion
             (while (setq button (previous-button (or pos (point))))
               (when (or (null type)     ;either any kind of button
                         (eq (button-type button) type)) ;if dir button
                 (throw 'hit button))
               (goto-char (button-start button)))))
          (progn
            (message (concat (or ok-message "Previous button") ": "
                             (tscan-button-target-name button name-face)))
            (tscan-button-act button (current-buffer) display))
        (tscan-ding (or error-message "No previous button"))))))
(repeatable-command-advice tscan-previous-button)

;; ---------------------------------------------------------------------------

(defun tscan-next-node (&optional arg pos display)
  "Move point to beginning of ARG:th next TScan node."
  (interactive "p\nd")
  (tscan-next-button nil display nil "No next node" "Next node"))
(repeatable-command-advice tscan-next-node)
(defun tscan-next-node-display (&optional arg pos)
  (interactive "p\nd")
  (tscan-next-node arg pos t))
(repeatable-command-advice tscan-next-node-display)

(defun tscan-previous-node (&optional arg pos display)
  "Move point to beginning of ARG:th previous TScan node."
  (interactive "p\nd")
  (tscan-previous-button nil display nil "First node" "Previous node"))
(repeatable-command-advice tscan-previous-node)
(defun tscan-previous-node-display (&optional arg pos)
  (interactive "p\nd")
  (tscan-previous-node arg pos t))
(repeatable-command-advice tscan-previous-node-display)

(defun tscan-first-node (&optional display)
  "Move point to beginning of first TScan node."
  (interactive)
  (with-current-buffer (tscan-current-buffer)
    (let ((p (point)))
      (goto-char (point-min))
      (if (tscan-next-node display) t
        (tscan-ding "No first node" p)))))
(defun tscan-first-node-display () (interactive) (tscan-first-node t))

(defun tscan-last-node (&optional display)
  "Move point to beginning of last TScan node."
  (interactive)
  (with-current-buffer (tscan-current-buffer)
    (let ((p (point)))
      (goto-char (point-max))
      (if (tscan-previous-node display) t
        (tscan-ding "No last node" p)))))
(defun tscan-last-node-display () (interactive) (tscan-last-node t))

;; ---------------------------------------------------------------------------

(defun tscan-next-dir (&optional arg pos display)
  "Move point to beginning of ARG:th next TScan directory."
  (interactive "p\nd")
  (tscan-next-button nil display 'tscan-dir-button "No next directory" "Next Directory"
                     'font-lock-directory-name-face))
(repeatable-command-advice tscan-next-dir)

(defun tscan-previous-dir (&optional arg pos display)
  "Move point to beginning of ARG:th previous TScan directory."
  (interactive "p\nd")
  (tscan-previous-button nil display 'tscan-dir-button "First directory" "Previous Directory"
                         'font-lock-directory-name-face))
(repeatable-command-advice tscan-previous-dir)

;; ---------------------------------------------------------------------------

(defun tscan-next-file (&optional arg pos display)
  "Move point to beginning of ARG:th next TScan fileectory."
  (interactive "p\nd")
  (tscan-next-button nil display 'tscan-file-button "Last file" "Next file"
                     'font-lock-file-name-face))
(repeatable-command-advice tscan-next-file)

(defun tscan-previous-file (&optional arg pos display)
  "Move point to beginning of ARG:th previous TScan fileectory."
  (interactive "p\nd")
  (tscan-previous-button nil display 'tscan-file-button "First file" "Previous file"
                         'font-lock-file-name-face))
(repeatable-command-advice tscan-previous-file)

;; ---------------------------------------------------------------------------

(defun tscan-next-symlink (&optional arg pos display)
  "Move point to beginning of ARG:th next TScan symbolic link file."
  (interactive "p\nd")
  (tscan-next-button nil display 'tscan-symlink-button "Last symlink" "Next symlink"
                     'tscan-symlink-file-face))
(repeatable-command-advice tscan-next-symlink)

(defun tscan-previous-symlink (&optional arg pos display)
  "Move point to beginning of ARG:th previous TScan symbolic link file."
  (interactive "p\nd")
  (tscan-previous-button nil display 'tscan-symlink-button "First symlink" "Previous symlink"
                         'tscan-symlink-file-face))
(repeatable-command-advice tscan-previous-symlink)

;; ---------------------------------------------------------------------------

(defun tscan-next-hit (&optional arg pos display)
  "Move point to beginning of ARG:th next TScan search hit."
  (interactive "p\nd")
  (tscan-next-button nil display 'tscan-hit-button "No next hit" "Next hit"
                     'tscan-hit-file-face))
(repeatable-command-advice tscan-next-hit)

(defun tscan-previous-hit (&optional arg pos display)
  "Move point to beginning of ARG:th previous TScan search hit."
  (interactive "p\nd")
  (tscan-previous-button nil display 'tscan-hit-button "No previous hit" "Previous hit"
                         'tscan-hit-file-face))
(repeatable-command-advice tscan-previous-hit)

;;; Inspired by `exps-next-error'.
(defun tscan-next-error-function (arg reset)
  "Navigate to ARG:th message/warning/error in most recent TScan buffer."
  (if (or reset
          ;;(null tscan-error-pos)
          )
      (progn
        (setq tscan-error-pos (point-min))
        (goto-char (point-min)))
    ;; (when tscan-error-pos (goto-char tscan-error-pos))
    )

  ;; (current-buffer) returns recent TScan buffer
  (if (<= arg 0)
      (tscan-previous-hit (- arg) tscan-error-pos 'select)
    (tscan-next-hit arg tscan-error-pos 'select))
  ;; (tscan-find-match (if (<= arg 0)
  ;;                       (tscan-previous-hit (- arg) tscan-error-pos t)
  ;;                     (tscan-next-hit arg tscan-error-pos t)))
  )

;; ---------------------------------------------------------------------------

(defun tscan-tpath-prefix (tpath)
  (concat
   (mapconcat (lambda (last)
                (if last
                    (make-string tscan-base-prefix-length ?\s)
                  tscan-in-prefix))
              (reverse (cdr tpath)) "")
   (if (car tpath)
       tscan-last-prefix
     tscan-base-prefix)))
;; (tscan-tpath-prefix '(nil nil))
;; (tscan-tpath-prefix '(nil t t))
;; (tscan-tpath-prefix '(t nil nil))
;; (tscan-tpath-prefix '(t t t))

(defun tscan-insert-dir (dirname lname fcache name tpath)
  "Insert TScan Directory DIRNAME."
  (set-buffer (tscan-buffer))
  (goto-char (point-max))
  (let* ((prefix (tscan-tpath-prefix tpath)
                 ;; (concat (make-string (* tscan-base-prefix-length (length tpath)) ?\s)
                 ;;         (if nil
                 ;;             tscan-last-prefix
                 ;;           tscan-base-prefix))
                 )
         (p (+ (point) (length prefix)))) ;start position
    (insert (propertize prefix 'face 'tscan-fs-conn-face) name "\n")
    (make-text-button p (+ p (length lname)) 'type 'tscan-dir-button 'target fcache)
    )
  ;; (redisplay)
  )

(defun tscan-insert-file (filename lname fcache name tpath)
  "Insert TScan File FILENAME."
  (set-buffer (tscan-buffer))
  (goto-char (point-max))
  (let* ((prefix (tscan-tpath-prefix tpath)
                 ;; (concat (make-string (* tscan-base-prefix-length (length tpath)) ?\s)
                 ;;         (if nil
                 ;;             tscan-last-prefix
                 ;;           tscan-base-prefix))
                 )
         (p (+ (point) (length prefix)))) ;start position
    (insert (propertize prefix 'face 'tscan-fs-conn-face) name "\n")
    (make-text-button p (+ p (length lname)) 'type 'tscan-file-button 'target fcache)
    ))

(defun tscan-insert-cluster-header (name count tpath cluster-depth &optional last-cluster)
  "Insert TScan Cluster header named NAME."
  (set-buffer (tscan-buffer))
  (goto-char (point-max))
  (let* ((prefix (concat (propertize (tscan-tpath-prefix tpath) 'face 'tscan-fs-conn-face)
                         ;; (make-string (+ (* tscan-base-prefix-length (length tpath))
                         ;;                 (* tscan-cluster-prefix-length cluster-depth))
                         ;;              ?\s)
                         (propertize (if last-cluster
                                         tscan-last-cluster-prefix
                                       tscan-cluster-prefix)
                                     'face 'tscan-hit-file-face)))
         (p (+ (point) (length prefix)))) ;start position
    (insert prefix
            (propertize name 'face 'tscan-cluster-name-face)
            (concat " " (propertize (number-to-string count) 'face 'tscan-hit-count-face))
            "\n")))

(defun tscan-insert-hit (fcache start end hit tpath &optional cluster-depth)
  "Insert TScan (Cluster) Hit in FCACHE."
  (set-buffer (tscan-buffer))
  (goto-char (point-max))
  (let* ((prefix (concat (propertize (tscan-tpath-prefix tpath) 'face 'tscan-fs-conn-face)
                         ;; (make-string (+ (* tscan-base-prefix-length (length tpath))
                         ;;                 (* tscan-cluster-prefix-length (or cluster-depth 0)))
                         ;;              ?\s)
                         (propertize tscan-hit-prefix 'face 'tscan-hit-file-face)))
         (p (+ (point) (length prefix)))) ;start position
    (insert prefix hit "\n")
    (make-text-button p (+ p (length hit)) 'type 'tscan-hit-button 'target (list fcache start end))
    ))

;; ============================================================================

(defun tscan-file-standard-hits (fcache hits tpath &optional cluster-depth)
  "Process FCACHE's contents scan hits list HITS at tpath TPATH and cluster depth CLUSTER-DEPTH."
  (let* ((cbeg-off-max 0))
    ;; pre-calculate statistics
    (dolist (hit hits)
      (let* ((lbeg (aref hit 0))         ;line beginning
             (cbeg (aref hit 5))         ;context beginning
             (cbeg-off (- cbeg lbeg))    ;line-offset to hit-begin
             )
        (setq cbeg-off-max (max cbeg-off-max cbeg-off))))

    (dolist (hit hits)
      (let* ((lbeg (aref hit 0))         ;line beginning
             (lend (aref hit 1))         ;line end
             (lstr (aref hit 2))         ;line string

             (hbeg (aref hit 3))         ;hit beginning
             (hend (aref hit 4))         ;hit end

             (cbeg (aref hit 5))         ;context beginning
             (cend (aref hit 6))         ;context end

             (hit-fcache (aref hit 7))   ;hit fcache

             (hbeg-off (- hbeg lbeg))     ;line-offset to hit-begin
             (hend-off (- hend lbeg))     ;line-offset to hit-end

             (bin-flag)                  ;binary hit

             alignment                  ;hit/context alignment
             )
        (when bin-flag (add-text-properties 0 (length lstr) (list 'face 'tscan-bin-hit-face) lstr)) ;highlight binary hit in dark
        (when (and cbeg cend)
          (let ((cbeg-off (- cbeg lbeg))  ;line-offset to context-begin
                (cend-off (- cend lbeg))  ;line-offset to context-end
                )
            (add-text-properties cbeg-off cend-off (list 'face 'tscan-hit-delim-face) lstr) ;highlight hit context
            (when tscan-align-hits-flag
              (setq alignment (- cbeg-off-max cbeg-off)))))
        (add-text-properties hbeg-off hend-off (list 'face 'tscan-hit-face) lstr) ;highlight hit

        ;; check for other hits in same context and highlight them
        (when nil                        ;TODO: Move this logic to cscan.el.
          (let (hbeg1 hend1)
            (while (and hits
                        (setq hbeg1 (car hits)) ;other hit beginning
                        (setq hend1 (cadr hits)) ;other hit end
                        (> hbeg1 lbeg) ;other hit after beginning of (line) context
                        (< hend1 lend))   ;other hit before end of (line) context
              (let ((lbeg1 (- hbeg1 lbeg)) ;line-offset to hit-begin
                    (lend1 (- hend1 lbeg))) ;line-offset to hit-end
                (add-text-properties lbeg1 lend1 (list 'face 'tscan-hit-face) lstr) ;highlight secondary hit on same line
                )
              (setq hits (cddr hits))    ;next hit-pair (next-next car)
              )))

        (tscan-insert-hit fcache hbeg hend
                          (concat
                           (when alignment (make-string alignment ? ))
                           lstr
                           (when nil
                             ;; insert line hit context as line numbers and offsets
                             (propertize
                              (concat " [" (number-to-string lbeg) "," (number-to-string lend) "]")
                              'face 'tscan-hit-attr-face))
                           )
                          tpath
                          cluster-depth))
      )))

(defun tscan-file-tree-clustered-hits (fcache hits tpath cluster-depth)
  "Process FCACHE's tree clustered scan hits HITS at tpath TPATH and cluster-depth CLUSTER-DEPTH."
  (mapc                               ;for each cluster
   `(lambda (cluster)
      (let* ((cid (aref cluster 0)) ;cluster id
             (cname (cscan-cluster-title cid))
             (ccount (aref cluster 1))         ;cluster count
             (cdata (aref cluster 2)))         ;cluster data
        (when (> ccount 0)      ;only display clusters that have hits
          (tscan-insert-cluster-header cname ccount ',tpath ,cluster-depth) ;insert header
          (cond ((vectorp (car cdata))    ;if first element is a vector
                 ;; clustered hits
                 (tscan-file-tree-clustered-hits ,fcache cdata ',tpath (1+ ,cluster-depth)))
                ((eq (car cdata) 'hits) ;trigger on header symbol `hits'
                 ;; standard hits
                 (tscan-file-standard-hits ,fcache (cdr cdata) ;skip header symbol
                                           ',tpath (1+ ,cluster-depth))))
          )))
   hits))

(defun tscan-file-flat-clustered-hits (fcache hits tpath cluster-depth)
  "Process FCACHE's flat clustered scan hits HITS at tpath TPATH and cluster-depth CLUSTER-DEPTH."
  (mapc                               ;for each cluster
   `(lambda (cluster)
      (let* ((cid (car cluster)) ;cluster id
             (cname (cscan-cluster-title cid))
             (ccount (cadr cluster))         ;cluster count
             (cdata (cddr cluster)))         ;cluster data
        (when (> ccount 0)      ;only display clusters that have hits
          (tscan-insert-cluster-header cname ccount ',tpath ,cluster-depth) ;insert header
          (tscan-file-standard-hits ,fcache cdata ;skip header symbol
                                    ',tpath (1+ ,cluster-depth))
          )))
   hits))

(defun tscan-file-top-hits (fcache hits tpath)
  "Process FCACHE's top scan hits HITS at tpath TPATH."
  (cond ((vectorp hits)
         ;; clustered hits
         (let ((type (aref hits 0)))
           (cond ((eq type 'clust)
                  (tscan-file-flat-clustered-hits fcache
                                                  (aref hits 2) ;skip header-id `clust' and COUNT
                                                  (cons nil tpath) 0))
                 ((eq type 'clust-tree)
                  (tscan-file-tree-clustered-hits fcache
                                                  (aref hits 2) ;skip header-id `clust-tree' and COUNT
                                                  (cons nil tpath) 0))
                 )))
        ((listp hits)
         (tscan-file-standard-hits fcache hits tpath))
        ))

(defun tscan-file-hit-count (hits)
  "Return Hit Count of HITS."
  (cond ((vectorp hits)                 ;clustered
         (aref hits 1)
         )
        ((listp hits) ;normal (unclustered) `match-data'-format (BEG-1 END-1 BEG-2 END-2 ...)
         (/ (length hits) 2))))

(defun tscan-file-links-string (sln &optional slt)
  "Follow all levels of symbolic links of SLN with symbolic link
SLT and return a nice illustrating string."
  (unless slt (setq slt (file-symlink-p sln)))
  (let (slt-string)                    ;symbolic link target string
    (while slt                         ;while link target
      (let* ((abs-slt (if (file-name-absolute-p slt) slt ;if absolute just set it
                        (expand-file-name slt (file-name-directory sln))))
             (exists (file-exists-p abs-slt)))
        (setq slt-string (concat slt-string
                                 " -> " (propertize slt 'face
                                                    (if exists
                                                        'tscan-symlink-target-face
                                                      'tscan-symlink-missing-target-face))
                                 (unless exists
                                   (propertize " missing-link" 'face 'tscan-hit-attr-face))))
        (let ((sllt (file-symlink-p abs-slt))) ;symlink-link-target
          (setq sln slt                        ;link becomes file name
                slt sllt))))
    slt-string))
;; Use: (tscan-file-links-string (elsub "mine/tscan-tests/abs-dir-link/etc"))

(defun tscan-fcache-links-string (sln slt-cache)
  "Follow all levels of symbolic links of SLN with symbolic link
SLT and return a nice illustrating string."
  (let ((slt-fname (fcache-full-fname slt-cache))
        (slt-full-fname (fcache-full-fname slt-cache)))
    (let (slt-string)                    ;symbolic link target string
      (while slt                         ;while link target
        (let* ((abs-slt (if (file-name-absolute-p slt) slt ;if absolute just set it
                          (expand-file-name slt (file-name-directory sln))))
               (exists (file-exists-p abs-slt)))
          (setq slt-string (concat slt-string
                                   " -> " (propertize slt 'face
                                                      (if exists
                                                          'tscan-symlink-target-face
                                                        'tscan-symlink-missing-target-face))
                                   (unless exists
                                     (propertize " missing-link" 'face 'tscan-hit-attr-face))))
          (let ((sllt (file-symlink-p abs-slt))) ;symlink-link-target
            (setq sln slt                        ;link becomes file name
                  slt sllt))))
      slt-string)))
;; Test:
(when nil
  (let* ((sln (elsub "mine/tscan-tests/abs-dir-link/etc"))
         (fcache sln)
         (slt (when (fcache-symlink-p fcache)
                (fcache-follow-link fcache))))
    (tscan-fcache-links-string sln slt)))

(defun tscan-sub-file (asub sub fcache slt rd nhits tpath fmatcher cmatcher)
  "Scan file ABS-SUB."
  (let* ((fhit (or (not `,fmatcher) (funcall `,fmatcher asub))) ;file filter matcher pass
         (chits (and fhit rd `,cmatcher (funcall `,cmatcher asub))) ;content filter matcher hits
         (dcache (fcache-parent-dcache fcache))
         ;;(parent-filename (dcache-fname dcache))
         )
    (when (or (null cmatcher) ;either file system just traversal (UNIX tree command) or
              nhits           ;filename matched or
              chits)          ;contents matched
      (let ((comp (and rd (file-compressed-p asub))) ;compressed
            (fsub (propertize sub 'face
                              (if slt (if rd 'tscan-symlink-file-face
                                        'tscan-unreadable-symlink-file-face)
                                (if rd
                                    (if fhit 'tscan-hit-file-face
                                      'tscan-uneditable-file-face)
                                  'tscan-unreadable-file-face)))))
        (when nhits (add-text-properties (car nhits) (cadr nhits)
                                         (list 'face 'tscan-hit-face) fsub)) ;highlight directory name hit count
        (tscan-insert-file asub sub fcache
                           (concat
                            ;; File Name
                            fsub

                            ;; Symbolic Links
                            (when slt (tscan-file-links-string asub)) ;show its targets

                            ;; Attributes
                            (unless rd (concat " " (propertize "unreadable" 'face 'tscan-hit-attr-face)))
                            (when comp (concat " " (propertize "compressed" 'face 'tscan-hit-attr-face)))
                            (unless fhit (concat " " (propertize "skipped" 'face 'tscan-hit-attr-face)))

                            ;; File Types
                            (when rd
                              (let ((type-names (file-type-names asub t 'tscan-file-type-face '(Editable Editable-Dir))))
                                (when type-names
                                  (concat " " type-names)))) ;types (keys)

                            ;; TODO: Show stat for missing links?
                            (let ((fsize (fcache-fsize fcache)))
                              (when fsize
                                (concat " [" (propertize (file-size-human-readable fsize 'si) 'face 'tscan-file-size-face) "]")))

                            ;; VC State
                            (when (and (boundp 'vc-root-dir)
                                       vc-root-dir
                                       vc-root-states)
                              (let ((vcs ;;(fcache-vc-state-cached fcache) ;Note: Intead of (vc-state asub) or (cdr (assoc sub d-vc-states))
                                     (or (gethash (file-relative-name asub vc-root-dir)
                                                  vc-root-states)
                                         'up-to-date)))
                                (when vcs
                                  (concat " "
                                          (propertize "VC" 'face 'font-lock-variable-name-face)
                                          ":"
                                          (propertize (symbol-name vcs) 'face 'tscan-hit-attr-face)
                                          "@"
                                          (propertize (abbreviate-file-name vc-root-dir) 'face 'font-lock-directory-name-face)))))

                            ;; Hits
                            (when chits
                              (let ((hit-count (tscan-file-hit-count chits)))
                                (when (> hit-count 0)
                                  (setq tscan-total-hit-count
                                        (+ tscan-total-hit-count hit-count))
                                  (if t
                                      (concat " H#:" (propertize (number-to-string hit-count) 'face 'tscan-hit-count-face))
                                    (propertize (format " hits:%d" (faze hit-count 'number))
                                                'face 'tscan-hit-attr-face))))) ;show it
                            )
                           tpath)))
    (when chits (tscan-file-top-hits fcache chits tpath))))

(defun tscan-sub-dir ()
  )

(require 'svn-entries nil t)

(defun tscan-sub-any (sub fcache)
  "Scan Sub File or Directory having local/relative name SUB.
Uses its file cache FCACHE."
  (let* ((dcache (fcache-parent-dcache fcache))
         (last-sub (progn (dcache-inc-iter dcache)
                          (= (dcache-get-iter dcache)
                             (dcache-subs-count dcache))))
         (tpath (cons last-sub tpath))
         (asub (concat directory "/" sub))             ;absolute sub filename
         (rd (fcache-readable fcache))                 ;readable flag
         (sl (fcache-symlink-p fcache))                ;symbolic link
         (slt (when sl (fcache-follow-link fcache t))) ;symbolic link target (if any)
         (nhits (when (and nmatcher (funcall nmatcher sub)) (match-data)))) ;name matcher hit

    ;; TODO: Percentage progress reporter instead?
    (when nil
      (message (concat "Scanning sub file/directory "
                       (faze sub 'tscan-symlink-file-face)
                       (when slt
                         (concat " -> "
                                 (faze slt 'tscan-symlink-target-face))))
               ))

    (if (or (fcache-directory-p fcache)        ;if a directory
            (and slt (fcache-directory-p slt)) ;or a symlink to a directory
            )
        ;; Sub-Directory
        (when (if remote           ;either local
                  (and             ;remote connections don't have relative names
                   (not (string= asub directory)) ;on remote hosts "." is converted to directory
                   (not (string= asub parent)) ;on remote hosts ".." is converted to parent directory
                   )
                (or (not dfmatch) ;if no dfmatch we have already filtered out "." and ".."
                    (string-match directory-files-no-dot-files-regexp sub))
                )
          (let* ((dacc (file-executable-p directory)) ;if directory is executable (accessible)
                 (dhit (or (not dmatcher) (funcall dmatcher asub)))
                 (dsub (propertize sub 'face (if (not rd) 'tscan-unreadable-directory-face
                                               (if dhit 'tscan-hit-directory-face
                                                 'tscan-skipped-directory-face)))))
            (when nhits
              (add-text-properties (car nhits) (cadr nhits)
                                   (list 'face 'tscan-hit-face) dsub)) ;highlight file name hit
            (tscan-insert-dir asub sub fcache
                              (concat dsub
                                      "/"

                                      ;; symbolic links
                                      (when sl (tscan-file-links-string asub)) ;show its targets

                                      ;; attributes
                                      (unless dhit (propertize " skipped" 'face 'tscan-hit-attr-face))
                                      (unless dacc (propertize " unaccessible" 'face 'tscan-hit-attr-face))

                                      ;; file types
                                      (if rd (concat " " (file-type-names asub t 'tscan-file-type-face '(Editable Editable-Dir)))
                                        (propertize " unreadable" 'face 'tscan-hit-attr-face))

                                      ;; directory size
                                      (when (and dacc rd (not sl))
                                        (let ((fsizes (dcache-dir-subs-fsize-sum (dcache-of asub) 'separate)))
                                          (when fsizes
                                            ;; TODO: Format fsizes as in `size-indication-mode'.
                                            (concat " ["
                                                    (propertize (file-size-human-readable (car fsizes) 'si) 'face 'tscan-file-size-face)
                                                    "+"
                                                    (propertize (file-size-human-readable (cdr fsizes) 'si) 'face 'tscan-file-size-face)
                                                    "]"))))
                                      (tscan-directory-svn-string asub)
                                      )
                              tpath)
            (if (and rd dacc dhit (not slt)) ;don't follow directory symbolic links
                (let ((subs (tscan-directory asub dfmatch nosort
                                             tpath (when max-depth (1- max-depth))
                                             dmatcher fmatcher cmatcher nmatcher)))
                  (cons sub subs)       ;Note: return (dir . dir-contents)
                  )
              (cons sub 'symlink))))    ;Note: return (DIR . 'symlink)
      ;; Sub-File
      (tscan-sub-file asub sub fcache slt rd nhits tpath fmatcher cmatcher))))

(defun tscan-sub-fcache (fcache)
  (tscan-sub-any (fcache-fname fcache) fcache))

(defvar tscan-sub-counts nil
  "Diretory Sub-File Counters")

(defvar tscan-sub-totals nil
  "Diretory Sub-File Totals")

;; (defun tscan-vc-directory (directory)
;;   (let* ((hit (file-under-vc-directory-p directory))
;;          (root (car hit))
;;          (backend (cdr hit)))
;;     (when (and root backend)
;;       (message "Scanning directory %s's Version Control using %s at %s"
;;                (faze directory 'dir)
;;                (symbol-name backend)
;;                (faze root 'dir))
;;       (directory-cache-vc-state-subs directory nil nil nil backend))))

(defun tscan-directory (directory
                        &optional dfmatch nosort
                        tpath max-depth
                        dmatcher fmatcher
                        cmatcher nmatcher)
  "Scan all sub-directories and files under DIRECTORY and
construct a tree of the results. DMATCHER/FMATCHER determines
which directory/file to Enter/Investigate. CMATCHER scans the
content of each investigated file's. NMATCHER scans the name of
each directory or file."
  (setq directory (directory-file-name directory)) ;Note: must remote last slash otherwise infinite recursion
  (when (or (not max-depth)                        ;either unlimited tpath
            (> max-depth 0))                       ;or explicit tpath
    (message "Scanning directory %s"
             (faze directory 'dir))
    ;;(tscan-vc-directory directory)
    (let* ((directory directory)
           (dfmatch dfmatch)
           (nosort nosort)
           (tpath tpath)
           (max-depth max-depth)
           (dmatcher dmatcher)
           (fmatcher fmatcher)
           (cmatcher cmatcher)
           (nmatcher nmatcher)

           (remote (file-remote-p directory)) ;pre-calc
           (parent (directory-file-name ;Note: must remote last slash otherwise infinite recursion
                    (file-name-directory directory))) ;pre-calc

           (dfiles (sort (hash-table-to-value-list
                          (fcache-dir-subs directory))
                         ;;'fcache-tscan-sub-lessp
                         'fcache-mtime-lessp
                         ))
           (vc-root-dir (car (file-under-vc-directory-p directory)))
           (vc-root-states (when vc-root-dir
                             (vc-roots-states-get vc-root-dir)))

           ;;(dfiles (directory-files directory t (or dfmatch directory-files-no-dot-files-regexp)))
           ;;(dfiles (fcache-dir-files directory t dfmatch))
           ;; (dfiles (progn
           ;;           (when (file-under-vc-directory-p directory)
           ;;             (setq tscan-vc-sort t)
           ;;             (message "Sorting %s on VC-state" directory))
           ;;           (sort dfiles 'tscan-file-lessp)))
           )
      (dcache-reset-iter (dcache-of directory))
      ;;(message "dfiles: %s" (mapcar 'fcache-fname dfiles))
      (if (hash-table-p dfiles)
          (maphash 'tscan-sub-any dfiles)
        (mapc 'tscan-sub-fcache dfiles))
      ;;(setq result (delq nil result))
      )))
(defalias 'dir-tree 'tscan-directory)
;; Use: (tscan-directory "/etc" "\.d$")
;; Use: (tscan-directory "/etc" "file")
;; Use: (tscan-directory "/etc")
;; Use: (tscan-directory "~/cognia")
;; Use: (tscan-directory (elsub "mine/tscan-tests"))

(let ((dfmatch "file"))
  (directory-files (elsub "mine/") t (if dfmatch
                                           (concat "\\(?:" dfmatch "\\)"
                                                   "\\|"
                                                   "\\(?:" directory-files-no-dot-files-regexp "\\)")
                                         directory-files-no-dot-files-regexp)))

(defun tscan-buffer-name-of-dir (directory &optional key-string)
  (concat "*" tscan-buffer-prefix ":"
          key-string
          "@"
          (directory-file-name          ;strip last slash
           (expand-file-name   ;canonicalize
            directory)) "*"))
;; Use: (tscan-buffer-name-of-dir "~/pnw/" "boost")

(defun tscan-get-buffer (directory &optional key-string)
  "Return the buffer of a TScan for KEY-STRING in DIRECTORY."
  (let ((buffer-name (tscan-buffer-name-of-dir directory key-string)))
    (get-buffer-create buffer-name)))
;; Use: (tscan-get-buffer "/etc")

(defun tscan-set-buffer (directory)
  (let ((buffer-name (tscan-buffer-name-of-dir directory)))
    (set-buffer (get-buffer-create buffer-name)))) ;set buffer which may be created if not already present
;; Use: (tscan-set-buffer "/etc")

(defun tscan-read-keys-at-point (&optional regexp-flag)
  "Read TScan keys and return them as a list of strings.
REGEXP-FLAG is non-nil if regexp strings are read, otherwise a
literal string are read."
  (multi-read-thing (concat "Search for "
                            (if regexp-flag "regexp" "string"))
                    (if regexp-flag 'regexp 'symbol-string-at-point)
                    t
                    (syntax-table)))

(defun tscan-keys-to-string (&optional keys regexp-flag)
  "Convert TScan KEYS to a string."
  (cond ((listp keys) ;string of keys to
         (if (> (length keys) 1)
             (prog1 (string-list-to-regexp keys regexp-flag 'any)
               (setq regexp-flag t))
           (car keys))) ;regexp
        ((stringp keys) ;keys string
         keys)          ;as is
        (t          ;default
         (error "Cannot handle keys of type %s" (type-of keys)))
        ))

(defun tscan-start (&optional keys directory regexp-flag noselect cache-empty)
  "Scan for KEYS in the contents of all files under DIRECTORY.
KEYS can be either a string or list of string.  If (all) KEYS is
downcased the scan ignores case, otherwise it defaults to the
value of `case-fold-search'."
  (interactive (list (tscan-read-keys-at-point)
                     (read-directory-name "Directory to scan: " nil nil t)))

  (let ((root-dir (file-under-vc-directory-p directory)))
    (when root-dir
      (vc-states-forget-directory
       (vc-root-path root-dir))))       ;remove backend for scan dir
  (vc-roots-clear-cached-states-under directory)
  (let* ((keys-string (tscan-keys-to-string keys regexp-flag))
         (regexp-flag (or (and (listp keys)
                               (> (length keys) 1))
                          regexp-flag))
         (case-fold-flag (when (downcased-p keys)
                           case-fold-search)))

    (add-to-history 'tscan-buffer-history (tscan-get-buffer directory keys-string))
    (setq next-error-last-buffer (tscan-buffer))
    (set-buffer (tscan-buffer))
    (tscan-mode)

    (setq tscan-root directory
          default-directory directory ;so that other tools, such as find-tag, starts in correct directory
          keys-string (unless (string= keys-string "") keys-string)
          tscan-pattern keys-string
          tscan-regexp-flag regexp-flag
          tscan-last-dir directory
          tscan-total-hit-count 0
          buffer-read-only nil)

    (erase-buffer)
    (redisplay)

    (if noselect (display-buffer (tscan-buffer)) (pop-to-buffer (tscan-buffer)))

    (message "%sScanning for \"%s\""
             (if tscan-regexp-flag "Regexp " "")
             (faze tscan-pattern 'regexp))

    (let ((start-time (float-time))
          (result (tscan-directory directory nil nil nil nil
                                   'file-editable-directory-p
                                   (when keys-string
                                     'file-editable-regular-p)
                                   (when keys-string
                                     `(lambda (filename) (cscan-file filename ,keys-string nil regexp-flag case-fold-flag
                                                                     'unbox-txt
                                                                     'clust ;Note: Currently only `clust' works now
                                                                     nil nil cache-empty)))
                                   (when keys-string
                                     (if regexp-flag
                                         `(lambda (filename) (file-name-match-regexp (file-name-nondirectory filename) ,keys-string))
                                       `(lambda (filename) (file-name-match-regexp (file-name-nondirectory filename) (regexp-quote ,keys-string)))))
                                   )))
      ;;(message "result:%s" result)
      (let ((elapsed (- (float-time) start-time)))
        (message "Scan found%s after %ss"
                 (if keys-string
                     (format " %s hits"
                             (faze
                              (with-current-buffer (tscan-current-buffer)
                                (if (zerop tscan-total-hit-count)
                                    "no"
                                  tscan-total-hit-count))
                              'number))
                   "")
                 (faze (format "%.1f" elapsed) 'number)))
      )

    (goto-char (point-min))
    (setq buffer-read-only t)
    (setq tscan-timer nil)

    (if (and keys-string
             (zerop tscan-total-hit-count))
        (progn (quit-window nil (get-buffer-window (tscan-buffer)))
               ;; (bury-buffer (tscan-buffer))
               )
      (shrink-window-if-larger-than-buffer ;auto-fit window
       (get-buffer-window (tscan-buffer)))))
  )
;; Use: (benchmark-run 1 (tscan-start "scan" (elsub "mine")))
;; Use: (benchmark-run 1 (rgrep "scan" nil (elsub "mine")))
;; Use: (tscan-start "obj" "~/cognia/hui")
;; Use: (tscan-start "xyz" "~/cognia/")
;; Use: (tscan-start "/etc")
;; Use: (tscan-start "/etc" "plugin")
;; Use: (tscan-start "/etc/X11" "plugin")
;; Use: (tscan-start "/etc/alternatives" "plugin")
;; Use: (benchmark-run 1 (tscan-start "/etc/alternatives" "plugin"))
;; Use: (tscan-start "~/tmp/" "a")
;; Use: (tscan-start "/tmp/per/" "input")

(defun tscan-start-regexp (&optional keys directory noselect)
  "Like `tscan-start' but KEYS are treated as regexp strings
instead of literal strings."
  (interactive (list (tscan-read-keys-at-point t)
                     (read-directory-name "Directory to scan: ")))
  (tscan-start keys directory t noselect))

(defun tscan-restart ()
  "Restart the current scan for the same key in the same directory tree."
  (interactive)
  (let ((buffer (tscan-current-buffer)))
    (if buffer
        (with-current-buffer buffer
          (tscan-start tscan-pattern tscan-root tscan-regexp-flag nil
                       t                ;cache empty hits to improve rescan
                                        ;performance when a small percentage of
                                        ;the files are hit-files
                       ))
      (message "No Current TScan buffer"))))

(defun tscan-search (string)
  "Start a new scan for STRING in the same directory tree."
  (interactive (list (read-symbol-string-at-point
                      (concat "Key (string) to rescan for")
                      (syntax-table))))
  (tscan-start string tscan-root tscan-regexp-flag))

(defun tscan-spawn-scan (secs directory)
  "Spawn a TScan."
  (setq tscan-timer (run-with-idle-timer secs nil 'tscan-restart directory)))
;; Use: (tscan-spawn-scan 2 "~/pnw")

(defun tscan-cancel-scan (directory)
  (when tscan-timer (cancel-timer tscan-timer)))
;; Use: (tscan-cancel-scan tscan-timer)

;; ============================================================================

(defun tscan-quit ()
  "Quit TScan buffer."
  (interactive)
  (quit-window)                         ;but don't delete it
  )

(defun tscan-kill ()
  "Kill TScan buffer."
  (interactive)
  (kill-buffer-and-window)
  )

;; ============================================================================

(defun tscan-default-global-keybindings ()
  "Set up global keybindings for `tscan'."
  (global-set-key [(meta ?g) (?<)] 'tscan-first-node)
  (global-set-key [(meta ?g) (?>)] 'tscan-last-node)

  (global-set-key [(meta ?g) (meta ?,)] 'tscan-previous-hit)
  (global-set-key [(meta ?g) (meta ?.)] 'tscan-next-hit)

  (global-set-key [(meta ?g) (?h)] 'tscan-next-hit)

  (global-set-key [(control c) (t)] 'tscan-start)
  (global-set-key [(control c) (meta t)] 'tscan-start-regexp)

  (global-set-key [(control c) (T)] 'tscan-restart)
  )

;; ============================================================================

(require 'pnw-findr nil t)

;; Note: See `findr-skip-directory-regexp' and `findr-skip-file-regexp'.
;; Note: This is a generalization of `findr-query-replace'() found in findr.el

(defun replace-in-directory-read-args (&optional delim-flag regexp-flag)
  "Read arguments for `query-replace-in-directory'() and return
them as a list."
  (let* ((default (if (use-region-p)
                      (buffer-substring-no-properties
                       (region-beginning)
                       (region-end))
                    (thing-at-point 'symbol)))
         (from (query-replace-read-from (concat "Replace (regexp) (default \"" default "\"): ") regexp-flag))
         (to (query-replace-read-to from (concat "Replace " from " with: ") regexp-flag))
         (fmatcher (fmd-read-multi-matcher 'name-recog t "Replace in files of types (default to all): "))
         (dir (read-directory-name
               (concat "Start in directory: ")))
         (delim (if delim-flag
                    (read-string
                     (concat "Word/Symbol/None Delimited Replace of "
                             from  " to " to " (w,s,[n]): ")) nil)))
    (if delim
        (list from to fmatcher dir delim)
      (list from to fmatcher dir)
      )))
;; Use: (replace-in-directory-read-args t t)
;; Use: (replace-in-directory-read-args nil t)

(defun replace-in-file-list (from to files &optional delim)
  "Replace Regular Expression FROM with TO
Recursively (Breadth-first) in FILES using delimited match
DELIM."
  (tags-query-replace (delimit-regexp from delim) to nil files))

(defun replace-regexp-in-filename (from to filename &optional delim query-type)
  "Replace Regular Expression FROM with TO
Recursively (Breadth-first) in the local part of the filenames
FILES using delimited match DELIM. Return new filename."
  (if (file-exists-p filename)
      (let* ((ln (file-name-nondirectory filename)) ;local name
             (dn (file-name-directory filename))    ;directory name
             (nn (replace-regexp-in-string (delimit-regexp from delim) to ln t))) ;new name
        (if (if (not (string= ln nn)) ;if ln really changed
                (if (file-exists-p (expand-file-name nn dn)) ;if new name already exists
                    (if (yes-or-no-p (concat "Replace " ln " with " nn
                                             " overwriting existing file (in directory) " dn " ?"))
                        (progn (rename-file-everywhere (expand-file-name ln dn)
                                                       (expand-file-name nn dn)) t))
                  (if (y-or-n-p (concat "Rename " ln " to " nn "? "))
                      (progn (rename-file-everywhere (expand-file-name ln dn)
                                                     (expand-file-name nn dn)) t))))
            (expand-file-name nn dn)
          filename
          ))
    (error "File %s not found!" filename)))
;; Use: (list (replace-regexp-in-filename "a" "A" "~/tmp/alpha") (replace-regexp-in-filename "A" "a" "~/tmp/AlphA"))

(defun replace-regexp-in-filenames (from to files &optional delim)
  "Replace Regular Expression FROM with TO
Recursively (Breadth-first) in the local part of the filenames
FILES using delimited match DELIM."
  (mapcar (lambda (filename)               ;fn is filename
            (replace-regexp-in-filename from to filename delim))
          files))
;; Use: (list (replace-regexp-in-filenames "a" "A" (directory-files "~/tmp/" t "a")) (replace-regexp-in-filenames "A" "a" (directory-files "~/tmp/" t "A")))

(defun query-replace-in-directory (from to fmatcher dir &optional delim)
  "Replace Regular Expression FROM with TO
Recursively (Breadth-first) in files whose names match the
filter (regexp) FMATCHER starting at directory DIR using delimited
match DELIM."
  (interactive (replace-in-directory-read-args t))
  (replace-in-file-list from to '(findr-scan fmatcher nil dir) delim))
;; Use: (query-replace-in-directory "int" "int" "operator-sheet\.*txt$" ".")x

(defun replace-in-directory-alt (from to fmatcher dir &optional delim)
  "Replace Regular Expression FROM with TO
Recursively (Breadth-first) in the filenames of the files
matching the filter (regexp) FMATCHER starting at directory DIR using
delimited match DELIM."
  (interactive (replace-in-directory-read-args t))
  (let* ((delim-from (delimit-regexp from delim))
         (files (findr-scan fmatcher nil dir)))
    (replace-regexp-in-filenames from to files delim)))

(defun replace-in-filenames-and-directory (from to fmatcher dir &optional delim)
  "Replace FROM to TO in all files whose names match FMATCHER recursively
in file system tree under DIR content and then rename these files
according to the same replace pattern from FROM to TO."
  (interactive (replace-in-directory-read-args t))
  (let ((files (findr-scan fmatcher nil dir)))
    (if (y-or-n-p "Rename (inside) Filenames? ")
        (setq files (replace-regexp-in-filenames from to files delim))) ; IMPORTANT: Rename before replace to please `before-save-hook', 'after-save-hook', `write-file-hook'.
    (if (y-or-n-p "Replace in Content? ")
        (replace-in-file-list from to files delim))))

(defun replace-symbol-in-filenames-and-directory (from to fmatcher dir)
  "Replace FROM (symbol-delimited) to TO in all files whose names
match FMATCHER recursively in file system tree under DIR content and
then rename these files according to the same replace pattern
from FROM to TO."
  (interactive (replace-in-directory-read-args))
  (replace-in-filenames-and-directory from to fmatcher dir 'symbols))

(defun prepend-to-symbols-in-files ())
(defun append-to-symbols-in-files ())

(global-set-key [(control c) (?%)] 'replace-in-filenames-and-directory)
(global-set-key [(control c) (?&)] 'replace-symbol-in-filenames-and-directory)

;; ============================================================================

;;;###autoload
(defun query-replace-regexp-in-file (regexp to-string filename
                                            &optional delimited start end context)
  "Perform query-replace-regexp() of REGEXP to TO-STRING in FILENAME."
  (interactive
   (let ((common (query-replace-read-args
                  (concat "Query replace"
                          (if current-prefix-arg " word" "") " regexp"
                          (if (use-region-p) " in region" ""))
                  t))
         (fname (read-file-name "Replace in file: "))
         (ctx (read-syntax-context))
         )
     (list (nth 0 common) (nth 1 common) fname (nth 2 common)
           ;; These are done separately here
           ;; so that command-history will record these expressions
           ;; rather than the values they had this time.
           (if (use-region-p) (region-beginning))
           (if (use-region-p) (region-end))
           ctx)))
  (save-excursion
    (when (file-writable-p filename)
      (find-file filename)
      (goto-char (point-min))               ;goto beginning of buffer
      (if (re-search-forward regexp nil t) ;Note: Speed improvement?
;;;         (if (case context
;;;               ('comment (at-syntax-comment-p (match-beginning 0)))
;;;               ('string (at-syntax-string-p (match-beginning 0)))
;;;               ('string-or-comment (at-syntax-string-or-comment-p (match-beginning 0)))
;;;               ('code (at-syntax-code-p (match-beginning 0)))
;;;               (t t))
          (query-replace-regexp regexp to-string delimited
                                (match-beginning 0) (point-max))))))
;; Use: (re-search-forward "alpha" nil t)
;; Use: (query-replace-regexp-in-file "alpha" "alpha" "~/pnw/tmp/dummy.h" nil 'any)
;; Use: (query-replace-regexp "alpha" "alpha" nil (match-beginning 0) (point-max))
;; Use: (query-replace-regexp-in-file "\\([^@]\\)TODO:" "\\1@todo:" "~/pnw/tmp/dummy.h")

;; ============================================================================

;;;###autoload
(defun query-apply-macro-in-file (filename &optional macro-name context)
  "Perform query-replace-regexp() of REGEXP to TO-STRING in FILENAME."
  (interactive (list (read-file-name "Apply macro in file: ")
                     (read-string "Macro name: ")
                     (read-syntax-context)))
  (save-excursion
    (when (file-writable-p filename)
      (find-file filename)
      (goto-char (point-min))               ;goto beginning of buffer
;;;         (if (case context
;;;               ('comment (at-syntax-comment-p (match-beginning 0)))
;;;               ('string (at-syntax-string-p (match-beginning 0)))
;;;               ('string-or-comment (at-syntax-string-or-comment-p (match-beginning 0)))
;;;               ('code (at-syntax-code-p (match-beginning 0)))
;;;               (t t))
      (kmacro-call-macro 0)))) ;repeat until error

;; Use: (directory-files "/etc" nil)
;; Use: (directory-files "/etc" t)
;; Use: (expand-file-name "passwd" "/etc")
;;;###autoload

;; ============================================================================

(defun do-in-ftree (fn root-dir &optional dmatcher fmatcher prompt-dirs prompt-files include-symlinks)
  "Apply the function FN (taking filename as single argument) for
every file matching FMATCHER in all sub-directories matching
DMATCHER under file system tree having ROOT-DIR as root
directory.

If the optional FMATCHER argument is non-nil, only
files which match it will be added to the cache."

  ;; Not an error, because otherwise we can't use load-paths that
  ;; contain non-existent directories.
  (if (not (file-accessible-directory-p root-dir))
      (message "Root-Dir %s does not exist" (faze root-dir 'dir))
    (let* ((dir       (expand-file-name root-dir))
           (comb-matcher nil)
           ;; Note: Because DMATCHER and FMATCHER may be very complex
           ;; regexps I don't think its wise to include here.

;;; 	   (comb-matcher (if (and (stringp dmatcher)
;;;                                   (stringp fmatcher))
;;;                             (concat dmatcher "\\|" fmatcher)
;;;                           nil))
           (sub-all (cddr (directory-files dir nil comb-matcher)))
           (dsubs nil)                  ;sub directories
           (fsubs nil)                  ;sub files
           )
      ;;(message "do-in-ftree: %s contains the %s file: %s" (faze root-dir 'dir) (length sub-all) sub-all)
      (mapcar
       (lambda (asub)
         (let ((sub (expand-file-name asub dir))) ;sub-file in absolute path form
           (if (and
                ;; Note: Not needed when we do `cddr' on result from `directory-files':
                ;; (file-name-real-p asub)
                                        ;Note: if not the special directories "." or ".."
                (or include-symlinks ;either we include all symbolic links or
                    (not (file-symlink-p sub)))) ;file is note a symbolic link
               (if (file-directory-p sub)	;Note: if @c sub is a directory
                   (when (string-match-generic dmatcher asub)
                     (let ((mess (format "Query Replace into directory %s (ToDo: y enters this, n skip this and all its subs, Y or ! enter this and all its sub-directories)?: " (faze sub 'dir))))
                       (when (or (not prompt-dirs) (y-or-n-p mess)) ;possibly prompt
                         (setq dsubs (append dsubs `(,sub))) ;add to directory list
                         (do-in-ftree ;Note: recurse directly (depth-first)
                          fn sub dmatcher fmatcher prompt-dirs prompt-files)
                         )))
                 ;; if @c sub is a file
                 (if (file-regular-p sub)
                     (when (string-match-generic fmatcher asub)
                       (let ((mess (format "Query Replace in file %s?: " (faze sub 'file))))
                         (when (or (not prompt-files) (y-or-n-p mess)) ;possibly prompt
                           (setq fsubs (append fsubs `(,sub))) ;add to files list
                           (funcall fn sub)         ;Note: We could also use (list sub)
                           ))))))))
       sub-all))))
;; Use: `(,c-file-offsets)
;; Use: (apply (lambda (x y) `[,x ,y]) '("a" "d"))
;; Use: (funcall (lambda (x y) `[,x ,y]) "a" "d")
(let (l)
  (setq l (append '(a b) '(c d) '(e f)))
  )
(let ((l '(a b)))
  (nconc l '(c d))
  (nconc l '(e f))
  )

(defun query-replace-regexp-in-ftree (regexp to-string root-dir
                                             &optional delimited start end context
                                             dmatcher fmatcher
                                             prompt-dirs prompt-files)
  "Replace some occurrences of REGEXP with TO-STRING in each file
matching FMATCHER in all sub-directories matching DMATCHER under
ROOT-DIR.

If the optional FMATCHER argument is non-nil, only files which
match it will be added to the cache.

Context can be either 'code, 'string, 'comment or a list
containing any of these.
"
  (interactive
   (let ((common (query-replace-read-args
                  (concat "Query replace"
                          (if current-prefix-arg " word" "")
                          " regexp"
                          (if (use-region-p) " in region" ""))
                  t))
         (rdir (read-directory-name "Replace under (root) directory: "))
         (ctx (read-syntax-context))
         )
     (list (nth 0 common) (nth 1 common) rdir (nth 2 common)
           ;; These are done separately here
           ;; so that command-history will record these expressions
           ;; rather than the values they had this time.
           nil nil ;Note: Don't make any sense to input these here!
           ctx
           nil nil ;ToDo: Input dmatcher nor fmatcher
           (y-or-n-p "Query for Specific Directories? ")
           (y-or-n-p "Query for Specific Files? ")
           )))
  (do-in-ftree (lambda (filename) (query-replace-regexp-in-file
                                   regexp to-string filename
                                   delimited start end context))
               root-dir dmatcher fmatcher prompt-dirs prompt-files)
  )
;; Use: (call-interactively 'query-replace-regexp-in-ftree)
;; Use:
(when nil
  (let ((dmatcher (fmd-matcher '(not VC-Db-Dir) 'name-recog))
        (fmatcher (fmd-matcher '(C C++) 'name-recog)))
    (query-replace-regexp-in-ftree "\\([^@]\\)todo:" "\\1@todo:"
                                   (expand-file-name "~/pnw/tmp/")
                                   t nil nil 'any
                                   dmatcher fmatcher
                                   nil nil)

    (query-replace-regexp-in-ftree "\\([^@]\\)todo:" "\\1@todo:"
                                   (expand-file-name "~/cognia/pmdb/")
                                   t nil nil 'any
                                   dmatcher fmatcher
                                   t t)

    (query-replace-regexp-in-ftree "vTex" "vtex"
                                   (expand-file-name "~/cognia/hui/")
                                   t nil nil 'any
                                   dmatcher fmatcher
                                   t t)

    (query-replace-regexp-in-ftree "vec" "vec"
                                   (expand-file-name "~/cognia/")
                                   t nil nil 'any
                                   dmatcher fmatcher
                                   t t)
    ))

(defun query-apply-macro-in-ftree (macro-name &optional context
                                              root-dir
                                              dmatcher fmatcher
                                              prompt-dirs prompt-files)
  "Replace some occurrences of REGEXP with TO-STRING in each file
matching FMATCHER in all sub-directories matching DMATCHER under
ROOT-DIR.

If the optional FMATCHER argument is non-nil, only files which
match it will be added to the cache.

Context can be either 'code, 'string, 'comment or a list
containing any of these.
"
  (do-in-ftree `(lambda (filename) (query-apply-macro-in-file
                                    filename ,macro-name ,context))
               root-dir dmatcher fmatcher prompt-dirs prompt-files)
  )

;;; ===========================================================================
;;; Editing Multiple Files in a Directory

(defmacro run-lisp-expressions-on-files (files &body expressions)
  "Run the EXPRESSIONS in FILES."
  `(dolist (file ,files)
     (with-temp-buffer (find-file file)
                       (unwind-protect (save-excursion ,@expressions)
                         (save-buffer)
                         (kill-buffer (current-buffer))))))

;; Use: (run-lisp-expressions-on-files (list "pnw-findr.el" "pnw-files-ops.el") (goto-char (point-min)))

(defun tscan-elp-benchmark ()
  "Benchmark a TScan."
  (interactive)
  (elp-instrument-package "any-search-")
  (elp-instrument-package "match-at-")
  (elp-instrument-package "cscan-")
  (elp-instrument-package "fmd-")
  (elp-instrument-package "file-")
  (elp-instrument-function 'expand-file-name)
  (elp-instrument-package "cscan-")
  (elp-instrument-package "tscan-")
  (elp-instrument-package "vc-")
  (elp-instrument-function 'add-text-properties)
  (elp-reset-all)
  (call-interactively 'tscan-start)
  (split-window-vertically)
  (elp-results)
  (elp-restore-all)
  )
(defalias 'tscan-profile 'tscan-elp-benchmark)
;; Use: (tscan-elp-benchmark)

(defun tscan-elp-benchmark-minimal ()
  "Benchmark a TScan."
  (interactive)
  (elp-instrument-package "tscan")
  (elp-instrument-package "fcache")
  (elp-instrument-package "cscan")
  (elp-reset-all)
  (tscan-start "filter" "~/elisp/mine")
  (split-window-vertically)
  (elp-results)
  (elp-restore-all)
  )
;; Use: (tscan-elp-benchmark-minimal)

;; ============================================================================

(provide 'tscan)
