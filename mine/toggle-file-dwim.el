;;; toggle-file-dwim.el --- Toggle Source File.
;; Author: Per Nordlöw <per.nordlow@gmail.com>

(require 'cc-assist)

;; ToDo: If semantic is not loaded use:
;; (if (memq (c-where-wrt-brace-construct) '(in-header in-block in-trailer))
(defun toggle-source-dwim (&optional other-window)
  "Toggle between Interface/Prototype (Header) and
Implementation (Source) (currently C, C++, Objective C) file in a
Do What I Mean (DWIM) style."
  (interactive)
  (if (or (cc-derived-mode-p)
          (eq major-mode 'ada-mode))
      (unless (and (fboundp 'semantic-analyze-proto-impl-toggle) ;check for Semantic
                   (ignore-errors (semantic-analyze-proto-impl-toggle)
                                  t)) ;Note: signal to ignore-errors that (semantic-analyze-proto-impl-toggle) worked
        (unless (and (fboundp 'ff-find-other-file)
                     (ff-find-other-file)
                     t)
          ;; Note: Not needed anymore.
          ;; (unless (and (require 'toggle-source nil t)
          ;;              (fboundp 'toggle-source)
          ;;              (toggle-source))
          ;;   ;; (y-or-n-p "No source present. Create one? ")
          ;;   )
          )

        ;; (unless (and (require 'eassist nil t)
        ;;              (fboundp 'eassist-switch-h-cpp)
        ;;              (ignore-errors (eassist-switch-h-cpp) t)) ;NOTE: Newer interface need argument `t'. Old takes none.
        ;;   )
        )
    (message "Toggle source is not needed nor relevant in %s" major-mode)))
(defalias 'clever-toggle-source 'toggle-source-dwim)
(global-set-key [(control x) (t)] 'toggle-source-dwim)
(defalias 'goto-other-source 'toggle-source-dwim)
(global-set-key [(meta g) (o)] 'goto-other-source)
(defun toggle-source-dwim-other-window ()
  (toggle-source-dwim t))
(global-set-key [(control x) (?4) (?t)] 'toggle-source-dwim)

(add-to-list 'toggle-source::mappings '("ads" . ".adb")) ;Ada Interface Source

(provide 'toggle-file-dwim)
