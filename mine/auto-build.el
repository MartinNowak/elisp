;;; auto-build.el --- Emacs Auto Build & Evaluate/Run/Execute.
;; Copyright (C) 2008 Per Nordlöw

;; TODO Make use of ELF SHA1-BuildID as in output from file: libclang.so: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, BuildID[sha1]=0xbe088ea4f64805016274fe79b47a86a7169e5881, not stripped
;; TODO Add Option: `Pointer-Arithmetic-Error-Detect' `-fmudflap'. Prevents buffer overflows and helps in catching dangling pointers.
;; TODO Add Option: `Stack-Overflow-Protect' `-fstack-check'
;; TODO Add Option: `Integer-Arithmetic-Overflow-Detect' `-gnato'

;; TODO Support Linux Trace Toolkit's (LTTng) User Space Trace (UST) by linking
;; to libust (-lust) and including including #include <ust/marker.h>. Then call usttrace
;; through :ust-trace operationX in filedb.el.
;; 1. gcc -o foo -lust foo.c
;; 2. usttrace ./foo
;; 3. Finally, open the trace in LTTV.
;;    lttv-gui -t /path/to/trace
;; 4. The trace can also be dumped as text in the console:
;;    lttv -m textDump -t /path/to/trace
;; See: http://lttng.org/files/ust/manual/ust.html
;; See: http://lttng.org/files/ust/manual/ust.html#Tracing-programs-and-libraries-that-were-not-linked-to-libust

;; TODO Use GCC's builtin features to auto-generate deps file X.d from along
;; with X.o. Parse this X.d to get header M.h and then find corresponding M.c,
;; compile and link with them.

;; TODO Run make if `makefile-targets' contains (file-name-sans-extension buffer-file-name) plus optional .out

;; TODO Integrate stuff from mode-compile.el.

;; TODO Only use `ccache' generated objects instead of files in

;; TODO Support clang in `compilation-error-regexp-alist-alist'. Google first.
;; TODO Support show GCC -fshow-column in `compilation-error-regexp-alist-alist' by modifying entry:
;; (gcc-include
;; "^\\(?:In file included \\|                 \\|\t\\)from \
;; \\(.+\\):\\([0-9]+\\)\\(?:\\(:\\)\\|\\(,\\|$\\)\\)?" 1 2 nil (3 . 4))

;; TODO Make use GCC's .d dependency file generated by each compilation.
;; TODO Support google-go gccgo-4.6.
;; TODO Ask for either ld or ld.gold as linker.
                                        ;: TODO Catch Compiler and Linker. Require setenv LANG to en_GB.utf8.
;;       -  "undefined reference to" => action: Lookup symbol and add linking properties for target fache.

;; `c-auto-build-directory'???

(when nil
  (when (require 'mode-compile nil t)
    ;;  (global-set-key "\C-cc" 'mode-compile)
    ;;  (global-set-key "\C-ck" 'mode-compile-kill)
    ))

(require 'main-function)
(require 'compiler-version)
(require 'cscan)

;; ---------------------------------------------------------------------------

(defgroup auto-build nil
  "Auto Build and Evaluate (Run/Execute) C/C++/Objective-C
Regions, Functions, Buffers and Files."
  :group 'tools)

(defcustom c-auto-build-directory "~/.emacs.d/auto-builds"
  "Directory to place auto built objects and executables."
  :group 'auto-build)

(defcustom c-auto-gen-deps t
  "Flags that auto-build should auto-generate deps.
Currently supported through GCC's flags -MD."
  :type 'boolean
  :group 'auto-build)

(defcustom default-build-type "Unspecified"
  "Default Build-Type name."
  :type 'string
  :group 'auto-build)

;; TODO Add .exe to Windows Targets
(defun auto-build-output-program (compiler filename &optional build-type)
  (let ((dir (expand-file-name (substring (file-name-directory (expand-file-name filename)) 1)
                               (expand-file-name (or build-type
                                                     default-build-type)
                                                 (expand-file-name
                                                  (file-name-nondirectory compiler)
                                                  c-auto-build-directory)))))
    (mkdir dir t)
    (expand-file-name (file-name-nondirectory (file-name-sans-extension filename)) dir)))
;; Use: (auto-build-output-program "/usr/bin/gcc" "~/foo.cpp" "Debug")
;; Use: (auto-build-output-program "gcc" "~/foo.cpp" "Debug")
;; Use: (auto-build-output-program "clang" "~/foo.cpp" "Debug")
;; Use: (auto-build-output-program nil "~/foo.cpp" "Debug")

(defun c-output-object (compiler filename &optional build-type)
  (concat (auto-build-output-program (or compiler "gcc") filename build-type) ".o"))
;; Use: (c-output-object "gcc" "~/foo.cpp" "Debug")
;; Use: (c-output-object "clang" "~/foo.cpp" "Debug")
;; Use: (c-output-object "clang" "~/foo.cpp" "Debug")

(defvar compilation-executee nil
  "File to execute upon compilation success.")

(defun auto-build-file-finished-callback (buffer-or-name &optional compile-status)
  "Handle result of Build in BUFFER-OR-NAME."
  (let ((try-last (and (boundp 'compilation-try-last)
                       compilation-try-last)))
    (with-current-buffer buffer-or-name
      (cond ((string= compile-status "finished\n")
             (when (and (boundp 'compilation-executee) ;if we should execute on compile finish
                        compilation-executee)          ;and non-nil
               (file-dwim compilation-executee
                          (if try-last 'try-last 'ask)       ;choose query or :execute
                          (if try-last 'try-last nil)
                          nil
                          (get-buffer-window buffer-or-name)
                          nil
                          compilation-build-type
                          (if try-last
                              'try-last
                            'ask))))
            ((string= compile-status "exited abnormally with code 1\n")
             (message "Scan for error: undefined reference to 'SYMBOL_NAME and look them up apt- or lib-symbol-hash.")
             )))))
(add-hook 'compilation-finish-functions 'auto-build-file-finished-callback t)

(require 'misc-fns)

(defun d-file-imports (current &optional recursive-flag found-files)
  "Return files references by D Source File named FILENAME."
  (setq current (expand-file-name current))
  (unless found-files
    (setq found-files (list current)))
  (let ((dirname (file-name-directory current))
        (flatten t))
    (let* ((imported-files (delq nil
                                 (mapcar
                                  ;; converts module name to filename
                                  (lambda (module)
                                    (when (not (string-prefixes-p '("std." "core.") module))
                                      ;; TODO Split module name into parts and search for them in subdirs of filename
                                      (let* (
                                             ;; strip "elf." if inside directory with basename "elf"
                                             (module (string-strip-prefix module
                                                                          (concat (file-name-sans-directory
                                                                                   (directory-file-name dirname)) ".")))
                                             (imported-file (expand-file-name
                                                             ;; import name to imported-file
                                                             (concat (replace-regexp-in-string "\\." "/" module) ".d")
                                                             dirname))
                                             (package-file (expand-file-name "package.d"
                                                                             (expand-file-name module
                                                                                               dirname))))
                                        (cond ((file-readable-p imported-file)
                                               imported-file)
                                              ((file-readable-p package-file)
                                               package-file)))))
                                  (let ((regexp (eval `(rx bol
                                                           (* space)
                                                           (? (| "public"
                                                                 "private") (+ space))
                                                           "import"
                                                           (+ space)
                                                           (group (+ (| "." (regexp ,ID))))))))
                                    (cscan-file current
                                                regexp
                                                'code t t nil t nil 'string)))))
           (files (append imported-files
                          (when recursive-flag
                            (delq nil
                                  (mapcar (lambda (imported-file)
                                            (when (not (member imported-file found-files))
                                              (d-file-imports imported-file
                                                              recursive-flag
                                                              (append imported-files
                                                                      found-files))))
                                          imported-files))))))
      (if (not found-files)
          files
        (delete-dups
         (flatten
          files))))))
;; Use: (d-file-imports "~/justd/fs.d")
;; Use: (d-file-imports "~/justd/fs.d" t)

(defvar ddemangle-executable
  (executable-find "ddemangle")
  "D ddemangle executable.")

;; TODO Make use of argument ON-SUCCESS or merge with `auto-build-file-finished-callback' logic.
(defun auto-build-c-common-file (compiler lang filename
                                          &optional on-success build-type std out-filename cflags libs use-ccache gen-deps try-last)
  "Build C-like FILENAME and return the output object (program)."
  (interactive)
  (let ((fcache (fcache-of filename))
        (include-main-macro t))
    (unless lang (setq lang "c"))

    ;; Pick Default or Read New
    ;; TODO Functionize these
    (unless compiler
      (setq compiler (let* ((tag :build-compiler)
                            (val (fcache-get-tag fcache tag)))
                       (or (when try-last val)
                           (fcache-set-tag fcache tag
                                           (compilation-read-compiler
                                            lang val))))))
    (unless build-type
      (setq build-type (let* ((tag :build-type)
                              (val (fcache-get-tag fcache tag)))
                         (or (when try-last val)
                             (fcache-set-tag fcache tag
                                             (compilation-read-build-type nil
                                              compiler
                                              (fcache-get-tag fcache tag)))))))
    (unless std
      (setq std (let* ((tag :language-standard)
                       (val (fcache-get-tag fcache tag)))
                  (or (when try-last val)
                      (fcache-set-tag fcache tag
                                      (compilation-read-language-standard
                                       lang
                                       compiler
                                       (or (fcache-get-tag fcache tag)
                                           "D-2.0")))))))

    (when (string-equal lang "c++")
      (setq libs (let* ((tag :c++-library-suffix)
                        (val (fcache-get-tag fcache tag)))
                   (or (when try-last val)
                       (fcache-set-tag fcache tag
                                       (concat libs " -l"
                                               (second (compilation-read-c++-library-suffix)))))))
      (when (and (string-match "gcc" compiler)
                 (string-match (regexp-quote "-lc++") libs))
        (setq libs (concat libs " -nostdlib -lc"))))

    (let ((warn-flags (let* ((tag :warn-flags)
                             (val (fcache-get-tag fcache tag)))
                        (or (when try-last val)
                            (fcache-set-tag fcache tag
                                            (compilation-read-warn-type-flags
                                             compiler))))) ;TODO Use `compilation-read-warn-type' and lookup flags afterwards
          (has-main (file-main-function filename lang)))
      (unless out-filename (setq out-filename
                                 (if (or has-main
                                         (string-equal lang "d"))
                                     (auto-build-output-program compiler filename build-type)
                                   (c-output-object compiler filename build-type))))
      (let* ((split-height-threshold 1) ;force vertical split
             (ccache-exec (when (member (downcase lang)
                                        '("c" "c++"
                                          "objective-c" "objective-c++"))
                            (executable-find "ccache")))
             (is-dmd (string-match "dmd" compiler))
             (is-ldc (string-match "ldc" compiler))
             (is-ldmd2 (string-match "ldmd2" compiler))
             (is-gdc (string-match "gdc" compiler))
             (is-gnu (or (string-match "gdc" compiler)
                         (string-match "gcc" compiler)
                         (string-match "g++" compiler)
                         (string-match "gcj" compiler)
                         (string-match "gfortan" compiler)
                         (string-match "gnat" compiler)))
             (full-compiler (if (file-exists-p compiler)
                                compiler
                              (executable-find compiler))))
        (with-current-buffer
            (let* ((default-directory (file-name-directory filename))
                   (comint t)
                   (command (concat (when (and use-ccache
                                               ccache-exec)
                                      (concat ccache-exec " "))

                                    compiler

                                    ;; use -vcolumns argument if present as string in compiler binary
                                    (when (and (or is-dmd
                                                   is-ldc)
                                               (cscan-file full-compiler "vcolumns"))
                                      " -vcolumns")

                                    ;; (when is-dmd
                                    ;;   " -v")  ;show whole template instantiation stack

                                    (unless (or is-dmd
                                                is-ldc
                                                is-ldmd2)
                                      (concat " -x " lang)) ;language
                                    (unless (or is-dmd
                                                is-ldc
                                                is-ldmd2
                                                is-gdc)
                                      (when (and std
                                                 (not (eq std 'skip))
                                                 (not (eq std 'none)))
                                        (concat " -std=" std))) ;standard

                                    (when (and (not (string-equal lang "d"))
                                               (require 'endianess nil t))
                                      (concat " -DCONFIG_" (upcase (endianess)) "_ENDIAN"))

                                    (unless (string-equal (downcase lang) "d")
                                      (when include-main-macro
                                        " -D__MAIN__"))

                                    " " cflags ;compilation flags

                                    (let ((flags (compilation-build-type-flags
                                                  compiler build-type (file-name-directory out-filename) t)))
                                      (when flags
                                        " " (mapconcat 'identity flags " ")))

                                    (when (and (string-match "gcc" compiler)
                                               (compiler-version-at-least "4.8" compiler))
                                      " -fno-diagnostics-show-caret")

                                    (when (and (string-match "clang" compiler)
                                               (compiler-version-at-least "3.1" compiler))
                                      " -fno-caret-diagnostics")

                                    (when warn-flags
                                      (concat " " (mapconcat 'identity warn-flags " ")))

                                    " " (unless has-main
                                          (cond ((string-equal lang "d")
                                                 "-main") ;add default main() (e.g. for unittesting)
                                                (t
                                                 "-c"))) ;if no main compile as object
                                    (when (and (or gen-deps
                                                   c-auto-gen-deps)
                                               (or (string-match "gcc" compiler)
                                                   (string-match "clang" compiler))) ;TODO Will clang support this?
                                      (concat " -MD -MF " out-filename ".dep"))

                                    ;; compiled file
                                    " " (file-name-nondirectory filename)

                                    ;; import paths
                                    " -I.. -I../.. -I../../.."

                                    ;; imported local files
                                    (let ((local-imports (delete (expand-file-name filename)
                                                                 (d-file-imports filename t))))
                                      (when local-imports
                                        (concat " " (mapconcat 'identity local-imports " "))))

                                    ;; libraries
                                    (when libs
                                      (concat " " libs))

                                    ;; threading
                                    (unless (or is-dmd
                                                is-ldc
                                                is-ldmd2)
                                      " -lpthread")

                                    ;; output filename
                                    (if (or is-dmd
                                            is-ldc
                                            is-ldmd2)
                                        " -of"
                                      " -o ")
                                    out-filename

                                    )))
              (compile ;; demangle symbols in linker error messages
               (if (and (equal lang "d")
                        ddemangle-executable)
                   ;; see: http://stackoverflow.com/questions/16497317/piping-both-stdout-and-stderr-in-bash
                   ;; see: https://stackoverflow.com/questions/1221833/bash-pipe-output-and-capture-exit-status
                   (concat "set -o pipefail && " command " 2>&1 | ddemangle")
                 command) comint))

          ;; store compilation states locally in compilation buffer variables
          (set (make-local-variable 'compilation-try-last) try-last)
          (set (make-local-variable 'compilation-build-type) build-type)
          (set (make-local-variable 'compilation-out-filename) out-filename)
          (set (make-local-variable 'compilation-cflags) cflags)
          (set (make-local-variable 'compilation-libs) libs)
          (set (make-local-variable
                'compilation-error-regexp-alist)
               (cond (is-dmd '(dmd gnu))
                     (is-ldmd2 '(dmd))
                     (is-ldc '(gnu))
                     (is-gdc '(gnu))
                     (is-gnu '(gnu))
                     (t compilation-error-regexp-alist)))

          (if (or has-main
                  (string-equal lang "d"))
              (set (make-local-variable 'compilation-executee) out-filename) ;signal execution on finish
            (when (boundp 'compilation-executee)
              (delete-file-local-variable 'compilation-executee)) ;forget it
            ))))
    out-filename))

(defun auto-build-c-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  (auto-build-c-common-file nil "c" filename on-success build-type "gnu99" out-filename cflags
                            (concat libs "-lm") t nil try-last))
;; Use: (auto-build-c-file (expand-file-name "tscan-tests/foo.c"))
;;; TODO Support Adding "-I~/alt/include/c++/v1" aswell.
(defun auto-build-c++-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  (auto-build-c-common-file nil "c++" filename on-success build-type "gnu++1y" out-filename cflags
                            (concat libs "-lm") t nil try-last))
(defun auto-build-d-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  (auto-build-c-common-file nil "d" filename on-success build-type nil out-filename cflags
                            nil nil nil try-last))
(defun auto-build-objc-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  (auto-build-c-common-file nil "go" filename on-success build-type "gnu99" out-filename cflags
                            (concat libs "-lm -lobjc") t nil try-last))
(defun auto-build-go-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  (auto-build-c-common-file nil "go" filename on-success build-type 'skip out-filename cflags
                            (concat libs "-lm -lgo") nil nil try-last))
(defun auto-build-rust-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  (auto-build-c-common-file nil "rustc" filename on-success build-type 'skip out-filename cflags
                            (concat libs "-lm -lrust") nil nil try-last))

(defun auto-build-ada-file (filename &optional on-success build-type out-filename cflags libs try-last)
  (interactive)
  ;; gnatmake hi.adb creates hi
  ;; - gcc -c hi.adb
  ;; - gnatbind -x hi.ali
  ;; - gnatlink hi.ali
  (auto-build-c-common-file "gnatmake" "ada" filename on-success build-type 'skip out-filename cflags nil nil nil try-last))

(defun auto-build-haskell-file (filename &optional on-success build-type out-filename cflags libs try-last)
  "Build Haskell FILENAME and return the output object (program)."
  (interactive)
  (let* ((lang "haskell")
         (compiler (compilation-read-compiler lang))
         (std (compilation-read-language-standard lang))
         (warn-flags (compilation-read-warn-type-flags compiler)))
    (unless build-type (setq build-type (compilation-read-build-type nil compiler)))

    (let ((has-main (file-haskell-main-function filename)))
      (unless out-filename (setq out-filename
                                 (if has-main
                                     (auto-build-output-program compiler filename build-type)
                                   (c-output-object compiler filename build-type))))
      (with-current-buffer
          (let ((split-height-threshold 1) ;force vertical split
                (comint t))
            (compile (concat compiler
                             " " cflags   ;compilation flags
                             (when (string-match "^ghc" compiler)
                               " -fglasgow-exts") ;Enable most language extensions
                             " " (compilation-build-type-flags compiler build-type)
                             (when warn-flags
                               (concat " " warn-flags))
                             " " filename
                             (when libs
                               (concat " " libs))
                             " -o " out-filename) comint))
        (if has-main
            (set (make-local-variable 'compilation-executee) out-filename) ;signal execution on finish
          (when (boundp 'compilation-executee)
            (delete-file-local-variable 'compilation-executee)) ;forget it
          )))
    out-filename))
;; Use: (auto-build-haskell-file "~/bin/hello.hs" nil "Debug")
;; Use: (auto-build-haskell-file "~/bin/hello.hs" nil "Release")

;; ---------------------------------------------------------------------------

(when nil
  (defun c-build-and-run-alt ()
    (interactive)
    (if (compile
         ;; In bash use "TERM=emacs" and in csh use "set TERM=emacs" to
         ;; prevent colorgccrc from using Escape colors in Emacs.
         (concat "set TERM=emacs ; " compile-command buffer-file-name))
        (shell-command (concat "./" buffer-file-name))
      )))
;;(global-set-key [(control c) (control meta c)] 'c-build-and-run-alt)

(defvar lib-symbols-scan-process nil)

(defun lib-symbols-scan-completed (process change)
  (message "%s: %s!" process change)
  )

(defun c-find-lib-symbols (dir)
  "Lookup Symbols from Static/Shared Libraries under directory DIR."

  ;; find ldconfig libraries
  (when nil
    (let ((conf-files (directory-files "/etc/ld.so.conf.d" t nil)))
      (dolist (file conf-files)
        (let ((hits (cscan-file file "^.*\n" nil t nil nil t)))
          (message "hits: %s" hits))
        )))

  (let* ((default-directory dir)
         (output-buffer-name (concat " *symbols-scan@" dir "*")))

    (let* ((all (directory-files dir t nil t))
           (predicate (lambda (file)
                        (when
                            (and (not (file-symlink-p file))
                                 (file-elf-p file))
                          file)))
           (real (mapconcat predicate all " ")))
      (let ((output-buffer (get-buffer-create output-buffer-name)))
        (with-current-buffer output-buffer
          (setq buffer-read-only nil))
        (buffer-disable-undo output-buffer)
        (shell-command (concat "nm -DC " real) output-buffer)
        (with-current-buffer output-buffer
          (setq buffer-read-only t))
        ))

    (when nil
      (let* ((all (directory-files dir t nil t))
             (predicate (lambda (file)
                          (when
                              (and (not (file-symlink-p file))
                                   (file-elf-p file))
                            file)))
             (real (mapcar predicate all)))
        (setq real (delq nil real))
        (message "real: %s" real)

        (setq lib-symbols-scan-process
              (eval
               `(start-file-process "auto-build-lib-symbols-scan"
                                    output-buffer-name
                                    "nm" "-DC" ,@real)))
        (set-process-sentinel lib-symbols-scan-process
                              'lib-symbols-scan-completed) ;set completion callback
        ))))
;; Use: (c-find-lib-symbols "/lib")
;; Use: (benchmark-run 1 (c-find-lib-symbols "/usr/lib"))
;; Use: (c-find-lib-symbols "/etc")
;; (cscan-file "~/objs" "xxxxxxxxxx")

;; ---------------------------------------------------------------------------

(provide 'auto-build)
