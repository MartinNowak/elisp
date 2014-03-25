;;; pgo-unit-test.el --- Setup Unit Test Framework Integration

(when nil
  ;; ETest: Emacs Lisp testing framework
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/ETest
  ;; See: http://www.shellarchive.co.uk/content/etest.html
  (when (require 'etest nil t)
    ;; The only keybinding we make... hopefully
    (add-hook 'lisp-mode-hook (lambda () (local-set-key (kbd "C-c T") 'etest-execute)))
    (add-hook 'emacs-lisp-mode-hook (lambda () (local-set-key (kbd "C-c T") 'etest-execute)))
    (add-to-list 'auto-mode-alist '("\\.etest$" . emacs-lisp-mode))
    )

  ;; autotest.el - ZenTest's autotest integration with emacs.
  (require 'autotest nil t)

  ;; test-case-mode.el --- unit test front-end
  ;; It is extensible and currently comes with back-ends for JUnit,
  ;; CxxTest, CppUnit, Python and Ruby.  See:
  ;; http://nschum.de/src/emacs/test-case-mode/
  (when (require 'test-case-mode nil t)
    ;; To enable it automatically when opening test files:
    ;; (add-hook 'find-file-hook 'enable-test-case-mode-if-test)
    ;; If you want to run all visited tests after a compilation, add:
    ;; (add-hook 'compilation-finish-functions
    ;;           'test-case-compilation-finish-run-all)
    )

  ;; el-expectations.el --- minimalist unit testing framework
  (when (require 'el-expectations nil t)
    )
  )

(provide 'pgo-unit-test)
