;;; compile-command-default.el --- establish a default for M-x compile

;; Copyright 2008, 2009, 2010 Kevin Ryde

;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 9
;; Keywords: processes
;; URL: http://user42.tuxfamily.org/compile-command-default/index.html
;; EmacsWiki: CompilationMode

;; compile-command-default.el is free software; you can redistribute it
;; and/or modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; compile-command-default.el is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This spot of code lets you establish a default `compile-command' for
;; M-x compile etc.
;;
;; Each function in `compile-command-default-functions' can contemplate the
;; buffer filename, directory, contents, etc, and decide a compile-command
;; that should apply.  The included functions can setup to run Perl
;; development or test programs either directly or through the test harness.
;;
;; The operative part is really just the hack to `hack-local-variables' to
;; get a good point to establish a default.  The list of functions allows
;; wild tests for what to apply and when and to build something perhaps with
;; absolute directories etc.
;;
;; Currently when a file is renamed with `dired-do-rename' a buffer follows
;; to the new name but the compile-command is not recalculated.  This is no
;; good as the old name is left in that string.  Maybe the
;; `compile-command-default-functions' should be re-run in that case, though
;; maybe only if the compile-command was calculated by
;; compile-command-default and hasn't been edited manually subsequently (or
;; if always overriding the edited command would still be in the
;; `compile-history' list).
;;
;; See mode-compile.el for a bigger system geared more towards language
;; compiles like gcc etc.

;;; Emacsen:

;; Designed for Emacs 21 and up.  Works in XEmacs 21, probably works in
;; Emacs 20.

;;; Install:

;; Add to your .emacs
;;
;;     (require 'compile-command-default)
;;
;; By default it does nothing, you add the functions you like the sound of
;; `compile-command-default-functions'.  For example
;;
;;     (setq compile-command-default-functions
;;           '(compile-command-default-perl-pl))
;;
;; or
;;
;;     (add-hook 'compile-command-default-functions
;;               'compile-command-default-perl-pl)

;;; History:

;; Version 1 - the first version
;; Version 2 - allow .t files in subdirectories of /t
;; Version 3 - .t files under /devel too
;; Version 4 - show "Entering directory" with cd's
;;           - run .pl.gz too
;; Version 5 - undo defadvice on unload-feature
;; Version 6 - add -w to raw perl .t
;;           - clean compile-command-default-functions on other package unload
;; Version 7 - express dependency on 'advice
;; Version 8 - use Filter::gunzip or PerlIO::gzip for .pl.gz if available
;; Version 9 - 'cl for emacs20


;;; Code:

;; for `ad-find-advice' macro when running uncompiled
;; (don't unload 'advice before our -unload-function)
(require 'advice)

(eval-when-compile ;; for emacs20 `push'
  (require 'cl))

;;;###autoload
(defgroup compile-command-default nil "Compile-Command-Default"
  :prefix "compile-command-default-"
  :group 'compilation
  :link  '(url-link
           :tag "compile-command-default.el home page"
           "http://user42.tuxfamily.org/compile-command-default/index.html"))

(defcustom compile-command-default-functions nil
  "Functions calculating default `compile-command' values."
  :type 'hook
  :group 'compile-command-default)
;; ask `unload-feature' to purge `compile-command-default-functions' when a
;; package func in it is unloaded
(eval-after-load "loadhist"
  '(when (boundp 'unload-feature-special-hooks)
     (add-to-list 'unload-feature-special-hooks
                  'compile-command-default-functions)))
;; automatically `risky-local-variable-p' due to name `-functions'

;; This is a defadvice so it's re-run by M-x normal-mode.  An entry in
;; `find-file-hook' for instance doesn't get that.
;;
(defadvice hack-local-variables (after compile-command-default activate)
  "Possibly set a default `compile-command'."
  (and (not (ad-get-arg 0))  ;; not when doing a "mode-only" local vars crunch
       buffer-file-name      ;; only for file buffers

       ;; leave alone any explicit local variable value in the file;
       ;; must give buffer parameter explicitly for xemacs
       (not (local-variable-p 'compile-command (current-buffer)))

       (let ((result (run-hook-with-args-until-success
                      'compile-command-default-functions)))
         (if result
             (set (make-local-variable 'compile-command) result)))))

;; `-unload-function' only runs in emacs22 up, but that's fine since the
;; advice is harmless when everything else has unloaded, because
;; `run-hook-with-args-until-success' just returns nil if the given hook
;; variable `compile-command-default-functions' has been unbound.
;;
(defun compile-command-default-unload-function ()
  "Remove advice on `hack-local-variables'.
This is called by `unload-feature'."
  (when (ad-find-advice 'hack-local-variables 'after 'compile-command-default)
    (ad-remove-advice   'hack-local-variables 'after 'compile-command-default)
    (ad-activate        'hack-local-variables))
  nil) ;; and do normal unload-feature actions too

;;-----------------------------------------------------------------------------
;; perl module availability

(defvar compile-command-default-perl-pl--have-module-alist nil
  "Cached results of `compile-command-default-perl-pl--have-module'.")

(defun compile-command-default-perl-pl--have-module (module)
  "Return non-nil if Perl module MODULE is available.
This is an internal part of `compile-command-default-perl-pl'.
MODULE is a string like \"Foo::Bar\"."
  (cdr (or (assoc module compile-command-default-perl-pl--have-module-alist)
           (let ((elem (cons module
                             (eq 0 (call-process
                                    "perl" nil nil nil
                                    "-e" (concat "require " module))))))
             (push elem compile-command-default-perl-pl--have-module-alist)
             elem))))

;;-----------------------------------------------------------------------------
;; perl .pl and .pl.gz
  
(defun compile-command-default-perl-pl ()
  "Set `compile-command' to run perl on a .pl or .pl.gz file.
This is designed for use in `compile-command-default-functions'.
The command generated is

    perl /top/dir/foo.pl

or for .pl.gz one of the following, according to what modules are
available (checked on first visiting a .pl.gz),

    perl -MFilter::gunzip /some/dir/foo.pl.gz
    perl -e '{use open IN=>\":gzip\";require shift}' /dir/foo.pl.gz
    perl -MFilter::exec=zcat /some/dir/foo.pl.gz
    zcat /some/dir/foo.pl.gz | perl -

Running .pl.gz is handy on example programs stored compressed in
/usr/share/doc etc.  The module forms are preferred as they get
the filename into error messages.  Filter::gunzip or PerlIO::gzip
do better on __DATA__ sections (though not perfect).

The script filename is absolute so the command can be re-run from
a different directory (a buffer with a different current
directory) if you follow an error to a module, etc.

See `compile-command-default-perl-t-raw' for running development
or example programs with build and working directories included.

Filter::gunzip, PerlIO::gzip and Filter::exec are all available
from CPAN."

  ;; "Filter" dist 1.37 has a Filter::Decompress, but only as an example,
  ;; not installed as such, and only reading the Zlib RFC1950 format, not
  ;; gzip, so it doesn't suit here.

  (let ((case-fold-search nil)) ;; don't act on Makefile.PL
    (cond
     ((string-match "\\.pl\\'" buffer-file-name)
      (concat "perl " (shell-quote-argument buffer-file-name)))

     ((string-match "\\.pl\\.gz\\'" buffer-file-name)
      (cond ((compile-command-default-perl-pl--have-module "Filter::gunzip")
             (concat "perl -MFilter::gunzip "
                     (shell-quote-argument buffer-file-name)))

            ((and (compile-command-default-perl-pl--have-module "PerlIO::gzip")
                  (compile-command-default-perl-pl--have-module "open"))
             (concat "perl -e '{use open IN=>\":gzip\";require shift}' "
                     (shell-quote-argument buffer-file-name)))

            ((compile-command-default-perl-pl--have-module "Filter::exec")
             (concat "perl -MFilter::exec=zcat "
                     (shell-quote-argument buffer-file-name)))

            (t
             (concat "zcat " (shell-quote-argument buffer-file-name)
                     " | perl -")))))))

(custom-add-option 'compile-command-default-functions
                   'compile-command-default-perl-pl)

;;-----------------------------------------------------------------------------
;; perl .t files

(defun compile-command-default-perl-t-harness ()
  "Set `compile-command' to run a perl test harness on a t/*.t file.
This is designed for use in `compile-command-default-functions'.

The command is the same sort of thing \"make test\" from
ExtUtils::MakeMaker will run.  For example

    cd /top/dir; \\
    PERL_DL_NONLAZY=1 perl -MExtUtils::Command::MM \\
      -e \"test_harness(0,'blib/lib','blib/arch')\" t/foo.t

It includes a \"cd\" to the top level directory where a normal
\"make test\" runs.  An absolute path there means you can re-run
from elsewhere if you follow an error to a different file.

Test files in subdirectory like t/author/bar.t are run
similarly."

  (and (let ((case-fold-search nil)) ;; not .T
         (string-match "/\\(t/.*\\.t\\)\\'" buffer-file-name))
       (let ((topdir   (substring buffer-file-name 0 (match-beginning 1)))
             (filename (substring buffer-file-name (match-beginning 1))))
         (set (make-local-variable 'compile-command)
              (concat "cd " (shell-quote-argument topdir) "; \\\n"
                      "echo \"Entering directory \\``pwd`'\"; \\\n"
                      "PERL_DL_NONLAZY=1 perl -MExtUtils::Command::MM \\\n"
                      "  -e \"test_harness(0,'blib/lib','blib/arch')\" \\\n"
                      "  " (shell-quote-argument filename))))))

(custom-add-option 'compile-command-default-functions
                   'compile-command-default-perl-t-harness)

(defun compile-command-default-perl-t-raw ()
  "Set `compile-command' to run a perl t/*.t or devel/*.pl file.
This is designed for use in `compile-command-default-functions'.
The command is like

    cd /home/foo/proj/; \\
    echo \"Entering directory \\``pwd`'\"; \\
    perl -w -I /home/foo/proj/lib \\
         -I /home/foo/proj/blib/lib \\
         -I /home/foo/proj/blib/arch \\
         t/foo.t

The \"cd\" means it runs from the toplevel the same as a \"make
test\" does on a .t file and can be restarted from elsewhere if
you follow an error to a different directory.  The \"Entering
directory\" tells `compilation-mode' where it's running to follow
relative paths (see `compilation-directory-matcher').

\"-w\" is added to .t files because that's how \"make test\" will
run them.  It's not added for .pl files (but is best in the #! or
with \"use warnings\" in the usual way).

The \"-I\" paths get work-in-progress code from \"lib\" for the
latest, and \"blib\" for the last \"make\" if you keep .xs code
in the toplevel instead of under the \"lib\" tree.  The paths are
absolute in case the program does a chdir() elsewhere.

For .t files this is a raw run and you see all the output,
without the the usual Test::Harness.  See
`compile-command-default-perl-t-harness' for a harness command.

For reference, blib.pm \"-Mblib\" is not used to pick up the blib
directory because it dies if there's no such directory, which can
happen if you're trying some all-perl \"lib\" code without yet
having run Makefile.PL."

  ;; on MacOS blib.pm has "blib/$MacPerl::Architecture" instead of
  ;; "blib/arch", dunno if there's any merit trying to do the same here
  ;; (with a "-e" or something)
  ;;
  ;; FindBin::libs has some novel automated pickup of /lib dirs at or above
  ;; a script's location.  Not sure if you'd want that all the time though.
  ;;
  (and (let ((case-fold-search nil)) ;; not .T
         (string-match
          ;; .t file anywhere under /t/ or /devel/,
          ;; .pl under /devel/ or /examples/
          "\
/\\(\\(t\\|devel\\)/.*\\.t\
\\|\\(devel\\|examples\\)/.*\\.pl\\)\\'"
          buffer-file-name))
       (let* ((topdir   (substring buffer-file-name 0 (match-beginning 1)))
              (filename (substring buffer-file-name (match-beginning 1)))
              ;; -w for .t files, per Test::Harness $Switches
              (warnings (if (match-beginning 2) "-w " ""))
              (libdir   (concat topdir "lib"))
              (blibdir  (concat topdir "blib/lib"))
              (archdir  (concat topdir "blib/arch")))
         (set (make-local-variable 'compile-command)
              (concat "cd " (shell-quote-argument topdir) "; \\\n"
                      "echo \"Entering directory \\``pwd`'\"; \\\n"
                      "perl " warnings "-I " (shell-quote-argument libdir) " \\\n"
                      "     -I " (shell-quote-argument blibdir) " \\\n"
                      "     -I " (shell-quote-argument archdir) " \\\n"
                      "     " (shell-quote-argument filename))))))

(custom-add-option 'compile-command-default-functions
                   'compile-command-default-perl-t-raw)

;; LocalWords: gcc gz pl gunzip MFilter zcat PerlIO usr MExtUtils ExtUtils MakeMaker proj blib Mblib xs chdir toplevel

(provide 'compile-command-default)

;;; compile-command-default.el ends here
