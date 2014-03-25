;;; mojo.el --- Interactive functions to aid the development of webOS apps
;; 2009-12-03 13:54:30
(defconst mojo-version "0.9.7")

(require 'json)

;; Copyright (c)2008 Jonathan Arkell. (by)(nc)(sa)  Some rights reserved.
;;              2009 Sami Samhuri
;; 
;; Authors: Jonathan Arkell <jonnay@jonnay.net>
;;          Sami Samhuri <sami.samhuri@gmail.com>
;; 
;; Latest version is available on github:
;;     http://github.com/samsonjs/mojo.el
;; 
;; This file is not part of GNU Emacs.
;; 
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation version 2.
;; 
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; For a copy of the GNU General Public License, search the Internet,
;; or write to the Free Software Foundation, Inc., 59 Temple Place,
;; Suite 330, Boston, MA 02111-1307 USA


;;; Commentary:
(defgroup mojo '()
  "Interactive functions to aid the development of webOS apps.

This package is in early beta.  I am open to any contributions or
ideas.  Send me a pull request on github if you hack on mojo.el.")

;;; Installation:
;;
;;  
;;  1. Put json.el and mojo.el somewhere in your load-path.
;;     (Use M-x show-variable RET load-path to see what your load path is.)
;;  
;;  2. Add this to your Emacs init file: (require 'mojo)
;;  
;;  3. Enable mojo-mode for modes that you use for webOS, e.g.:
;;  
;;  (mojo-setup-mode-hooks 'css-mode-hook 'js2-mode-hook
;;                         'espresso-mode-hook 'html-mode-hook)
;;  
;;     Note that this does not simply enable mojo-mode for these types
;;     wholesale, but instead only enables mojo-mode when it finds that
;;     the file is also under a Mojo project root (using mojo-project-p).
;;  
;;  4. Make sure you customize the variables:
;;     mojo-project-directory, mojo-sdk-directory and mojo-build-directory
;;     (Use M-x customize-group RET mojo RET)



;;; Commands:
;;
;; The complete command list:
;; 
;;   Code generation
;;   ---------------
;; 
;;  mojo-generate
;;    Generate a new Mojo application in the mojo-project-directory.
;;    
;;  mojo-generate-scene
;;    Generate a new Mojo scene for the application found by mojo-root.
;;    (a.k.a. the current application)
;; 
;; 
;;   Packaging and device/emulator interactions
;;   ------------------------------------------
;; 
;;  mojo-emulate
;;    Launch the palm emulator.
;; 
;;  mojo-package
;;    Package the specified application (defaults to current app id).
;; 
;;  mojo-install
;;    Install the specified package (defaults to current app id).
;;    The emulator needs to be running.
;; 
;;  mojo-list
;;    List all installed packages.
;; 
;;  mojo-delete
;;    Remove the specified application. (defaults to current app id)
;; 
;;  mojo-launch
;;    Launch the specified application in the emulator. (defaults to
;;    current app id)
;; 
;;  mojo-close
;;    Close specified application. (defaults to current app id)
;; 
;;  mojo-inspect
;;    Run the dom inspector on the specified application. (defaults to
;;    current app id)
;; 
;;  mojo-hard-reset
;;    Perform a hard reset, clearing all data.
;; 
;;  mojo-package-install-and-launch
;;    Package, install, and launch the current app.
;; 
;;  mojo-package-install-and-inspect
;;    Package, install, and launch the current app for inspection.
;; 
;;  mojo-target-device
;;    Set the target device to USB.
;; 
;;  mojo-target-emulator
;;    Set the target device to the emulator.
;; 
;;  mojo-toggle-target
;;    Automatically change the target device from 'usb' to 'tcp' and vice
;;    versa.
;; 
;; 
;;   Quickly switch buffers
;;   ----------------------
;; 
;;  mojo-switch-to-assistant
;;    Switch to the corresponding assistant from any view file.
;; 
;;  mojo-switch-to-view
;;    Switch to the main view from an assistant.
;; 
;;  mojo-switch-to-next-view
;;    Switch to the next view file, alphabetically.  Wraps around at the
;;    end.
;; 
;;  mojo-switch-to-appinfo
;;    Switch to the appinfo.json file.
;; 
;;  mojo-switch-to-sources
;;    Switch to the sources.json file.
;; 
;;  mojo-switch-to-index
;;    Switch to the root index.html file.
;; 
;;  mojo-switch-to-stylesheet
;;    Switch to the main stylesheet.


;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `mojo-sdk-directory'
;;    Path to where the mojo SDK is.
;;    default = (case system-type
;;	                ((windows-nt) "c:/progra~1/palm/sdk")
;;	                ((darwin) "/opt/PalmSDK/Current")
;;	                (t ""))
;;  `mojo-project-directory'
;;    Directory where all your Mojo projects are located.
;;    default = ""
;;  `mojo-build-directory'
;;    Directory to build Mojo applications in.
;;  `mojo-debug'
;;    Run Mojo in debug mode.  Assumed true while in such an early version.
;;    default = t

;; CHANGELOG
;; =========
;; 
;; sjs 2009-12-03
;; v 0.9.7 (hooks)
;; 
;;       - Added mojo-setup-mode-hooks which adds
;;         mojo-maybe-enable-minor-mode to the specified mode hooks.
;;         When the hooked modes are activated on files under a Mojo
;;         project root also activate mojo-mode.
;; 
;; sjs 2009-12-01
;; v 0.9.6 (minor mode)
;; 
;;       - Created mojo-mode, a minor mode with keybindings.
;; 
;;       - Prefixed *all* functions with "mojo-".
;; 
;; sjs 2009-11-24
;; v 0.9.5 (bug fix)
;; 
;;       - Now that I have a real Palm Pre device I was able to test
;;         device support.  Turns out I couldn't (easily) target the
;;         device because mojo-target-device was not interactive.
;;         Whoops.
;; 
;; sjs 2009-11-22
;; v 0.9.4 launch emulator if needed
;; 
;;       - Commands that use the emulator launch it if necessary and wait
;;         till it is fully booted before running commands.
;; 
;; sjs 2009-11-21
;; v 0.9.3 (one more bug fix for today)
;; 
;;       - Don't pass -d switch to commands that don't accept it.
;; 
;; sjs 2009-11-21
;; v 0.9.2 (bug fixes)
;; 
;;       - reading json files no longer messes up your buffer history.
;; 
;;       - app list completion works now (caching bug)
;; 
;; sjs 2009-11-21
;; v 0.9.1
;; 
;;       - Added mojo-package-install-and-launch.
;; 
;;       - New variable for specifying whether commands target the device
;;         or emulator, *mojo-target*.  Set it to 'usb' for a real device
;;         and 'tcp' for the emulator.  Defaults to 'tcp'.  To set the
;;         default target you can use the convenience functions
;;         mojo-target-device and mojo-target-emulator.
;; 
;; sjs 2009-11-20
;; v 0.9
;; 
;;       - Automatically find Mojo project root by searching upwards for
;;         appinfo.json.
;; 
;;       - Added command for generating new scenes, mojo-generate-scene.
;; 
;;       - mojo-package now operates only on the current project.
;; 
;;       - Parse appinfo.json to get version, used for installing &
;;         launching with less interaction.
;; 
;;       - mojo-install, mojo-launch, mojo-inspect, and mojo-delete still
;;         read in arguments but have the current project/app as the
;;         default values.
;; 
;;       - New convenience method: mojo-package-install-and-inspect
;; 
;;         This function only operates on the active app and does not
;;         read in any input.
;; 
;;       - Remembered filenames and app ids are cleared when the Mojo
;;         project root changes. (DWIM)
;; 
;;       - Parse output of `palm-install --list` for app id completion.
;;         App id completion was ported from cheat.el.
;; 
;; v 0.2 - Fixed some minor bugs
;; v 0.1 - Initial release


;;; Code:

(define-minor-mode mojo-mode
  "Toggle Mojo mode.
     With no argument, this command toggles the mode.
     Non-null prefix argument turns on the mode.
     Null prefix argument turns off the mode.
     
     When Mojo mode is enabled various commands are enabled to
     aid the development of Mojo applications.

     Make sure you customize the variables
     \\[mojo-project-directory], \\[mojo-sdk-directory] and
     \\[mojo-build-directory].

     Keybindings are:

      * C-c a     -- \\[mojo-switch-to-assistant]
      * C-c i     -- \\[mojo-switch-to-appinfo]
      * C-c I     -- \\[mojo-switch-to-index]
      * C-c n     -- \\[mojo-switch-to-next-view]
      * C-c s     -- \\[mojo-switch-to-sources]
      * C-c S     -- \\[mojo-switch-to-stylesheet]
      * C-c v     -- \\[mojo-switch-to-view]
      * C-c SPC   -- \\[mojo-switch-file-dwim]
      * C-c C-e   -- \\[mojo-emulate]
      * C-c C-p   -- \\[mojo-package]
      * C-c C-r   -- \\[mojo-package-install-and-inspect]
      * C-c C-s   -- \\[mojo-generate-scene]
      * C-c C-t   -- \\[mojo-toggle-target]

     See the source code mojo.el or the README file for a list of
     all of the interactive commands."
  ;; The initial value.
  :init-value nil
  ;; The indicator for the mode line.
  :lighter "-Mojo"
  ;; The minor mode bindings.
  :keymap
  '(("\C-ca" . mojo-switch-to-assistant)
    ("\C-ci" . mojo-switch-to-appinfo)
    ("\C-cI" . mojo-switch-to-index)
    ("\C-cn" . mojo-switch-to-next-view)
    ("\C-cs" . mojo-switch-to-sources)
    ("\C-cS" . mojo-switch-to-stylesheet)
    ("\C-cv" . mojo-switch-to-view)
    ("\C-c " . mojo-switch-file-dwim)
    ("\C-c\C-e" . mojo-emulate)
    ("\C-c\C-p" . mojo-package)
    ("\C-c\C-r" . mojo-package-install-and-inspect)
    ("\C-c\C-s" . mojo-generate-scene)
    ("\C-c\C-t" . mojo-toggle-target))
  :group 'mojo)

(defcustom mojo-sdk-directory
  (case system-type
	((windows-nt) "c:/progra~1/palm/sdk")
	((darwin) "/opt/PalmSDK/Current")
	(t ""))
  "Path to where the mojo SDK is.

Note, using the old-school dos name of progra~1 was the only way i could make
this work."
  :type 'directory
  :group 'mojo)

(defcustom mojo-project-directory ""
  "Directory where all your Mojo projects are located."
  :type 'directory
  :group 'mojo)

(defcustom mojo-build-directory ""
  "Directory where built projects are saved."
  :type 'directory
  :group 'mojo)

;;* debug
(defcustom mojo-debug t
  "Run Mojo in debug mode.  Assumed true while in such an early version."
  :type 'boolean
  :group 'mojo)

;; Call this from your emacs config file with the modes you want to hook.
(defun mojo-setup-mode-hooks (&rest hooks)
  "Add `MOJO-MAYBE-ENABLE-MINOR-MODE' to the specified mode hooks."
  (dolist (hook hooks)
    (add-hook hook 'mojo-maybe-enable-minor-mode)))

(defun mojo-maybe-enable-minor-mode ()
  (when (mojo-project-p)
    (mojo-mode)))

;;* interactive generate
(defun mojo-generate (title directory)
  "Generate a new Mojo application in the `mojo-project-directory'.

TITLE is the name of the application.
DIRECTORY is the directory where the files are stored."
  ;;TODO handle existing directories (use --overwrite)
  (interactive "sTitle: \nsDirectory Name (inside of mojo-project-directory): \n")
  (let ((mojo-dir (expand-file-name (concat mojo-project-directory "/" directory))))
	(when (file-exists-p mojo-dir)
		  (error "Cannot mojo-generate onto an existing directory! (%s)" mojo-dir))
	(make-directory mojo-dir)
	(mojo-cmd "palm-generate" (list "-p" (format "\"{'title':'%s'}\"" title)
					mojo-dir))
	(find-file (concat mojo-dir "/appinfo.json"))))

;;* interactive
(defun mojo-generate-scene (name)
  "Generate a new Mojo scene for the current application.

NAME is the name of the scene."
  (interactive "sScene Name: \n")
  (let ((mojo-dir (mojo-root t)))
    (mojo-cmd "palm-generate" (list "-t" "new_scene"
				    "-p" (format "name=%s" name) mojo-dir))
    (find-file (format "%s/app/assistants/%s-assistant.js" mojo-dir name))
    (find-file (format "%s/app/views/%s/%s-scene.html" mojo-dir name name))))

;;* interactive 
(defun mojo-emulate ()
  "Launch the palm emulator."
  (interactive)
  (unless (mojo-emulator-running-p)
    (mojo-cmd "palm-emulator" nil)))

;;* interactive 
(defun mojo-package ()
  "Package the current application into `MOJO-BUILD-DIRECTORY'."
  (interactive)
  (mojo-cmd "palm-package" (list "-o" (expand-file-name mojo-build-directory)
				 (mojo-root t))))

;;* interactive 
(defun mojo-install ()
  "Install the package named by `MOJO-PACKAGE-FILENAME'. The emulator needs to be running."
  (interactive)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-install" (list (expand-file-name (mojo-read-package-filename))))
  (mojo-invalidate-app-cache))

;;* interactive 
(defun mojo-list ()
  "List all installed packages."
  (interactive)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-install" (list "--list")))

;;* interactive 
(defun mojo-delete ()
  "Remove the current application using `MOJO-APP-ID'."
  (interactive)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-install" (list "-r" (mojo-read-app-id)))
  (mojo-invalidate-app-cache))

;;* interactive
(defun mojo-ensure-emulator-is-running ()
  "Launch the current application, and the emulator if necessary."
  (interactive)
  (if (string= "tcp" *mojo-target*)
      (progn
	(when (not (mojo-emulator-running-p))
	  (mojo-emulate)
	  (print "Launching the emulator, this will take a minute..."))
	(while (not (mojo-emulator-responsive-p))
	  (sleep-for 3))
	(print "Emulator has booted!"))
    (print "Connect your device if necessary.")))

;;* interactive 
(defun mojo-launch ()
  "Launch the current application in the emulator."
  (interactive)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-launch" (list (mojo-read-app-id))))

;;* interactive 
(defun mojo-close ()
  "Close launched application."
  (interactive)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-launch" (list "-c" (mojo-read-app-id))))

;;* launch interactive
(defun mojo-inspect ()
  "Run the DOM inspector on the current application."
  (interactive)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-launch" (list "-i" (mojo-read-app-id))))

;;* emulator interactive
(defun mojo-hard-reset ()
  "Perform a hard reset, clearing all data."
  (interactive)
  (mojo-cmd "palm-emulator" (list "--reset")))

(defun mojo-browse ()
  "Use `browse-url' to visit your application with Palm Host."
  (browse-url "http://localhost:8888"))


;;* interactive 
(defun mojo-package-install-and-inspect ()
  "Package, install, and launch the current application for inspection."
  (interactive)
  (mojo-package)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-install" (list (expand-file-name (mojo-package-filename))))
  (mojo-cmd-with-target "palm-launch" (list "-i" (mojo-app-id))))

;;* interactive 
(defun mojo-package-install-and-launch ()
  "Package, install, and launch the current application."
  (interactive)
  (mojo-package)
  (mojo-ensure-emulator-is-running)
  (mojo-cmd-with-target "palm-install" (list (expand-file-name (mojo-package-filename))))
  (mojo-cmd-with-target "palm-launch" (list (mojo-app-id))))


;;* interactive
(defun mojo-target-device ()
  "Specify that Mojo commands should target a real device.

Sets `*mojo-target*' to \"usb\"."
  (interactive)
  (setq *mojo-target* "usb"))

;;* interactive
(defun mojo-target-emulator ()
  "Specify that Mojo commands should target a real device.

Sets `*mojo-target*' to \"tcp\"."
  (interactive)
  (setq *mojo-target* "tcp"))


;;* interactive
(defun mojo-toggle-target ()
  "Automatically change the target device from 'usb' to 'tcp' and
vice versa."
  (interactive)
  (if (string= "usb" *mojo-target*)
      (mojo-target-emulator)
    (mojo-target-device)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some support functions that grok the basics of a Mojo project. ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun mojo-parent-directory (path)
  "Get the parent directory, i.e. the head of a path by dropping the last component."
  (if (< (length path) 2)
      path
    (substring path 0 (- (length path)
			 (length (mojo-filename path))
			 1)))) ;; subtract one more for the trailing slash

(defun mojo-filename (path)
  "Get the filename from a path, i.e. the last component, or tail."
  (if (< (length path) 2)
      path
    (let ((start -2))
      (while (not (string= "/" (substring path start (+ start 1))))
	(setq start (- start 1)))
      (substring path (+ start 1)))))

(defvar *mojo-last-root* ""
  "Last Mojo root found by `MOJO-ROOT'.")

(defun mojo-root (&optional ask)
  "Find a Mojo project's root directory starting with `DEFAULT-DIRECTORY'.
   If ASK is non-nil and no root was found, ask the user for a directory."
  (let ((last-component (mojo-filename default-directory))
	(dir-prefix default-directory))
    ;; remove last path element until we find appinfo.json
    (while (and (not (file-exists-p (concat dir-prefix "/appinfo.json")))
		(not (< (length dir-prefix) 2)))
      (setq last-component (mojo-filename dir-prefix))
      (setq dir-prefix (mojo-parent-directory dir-prefix)))

    ;; If no Mojo root found, ask for a directory.
    (when (and ask (< (length dir-prefix) 2))
      (setq dir-prefix (mojo-read-root)))

    ;; Invalidate cached values when changing projects.
    (if (or (mojo-blank *mojo-last-root*)
	    (not (string= dir-prefix *mojo-last-root*)))
	(progn
	  (setq *mojo-last-root* dir-prefix)
	  (setq *mojo-package-filename* nil)
	  (setq *mojo-app-id* nil)))

    dir-prefix))

;; foolproof?
(defun mojo-project-p ()
  (and (file-exists-p (concat (mojo-root) "/appinfo.json"))
       (file-exists-p (concat (mojo-root) "/sources.json"))
       (file-exists-p (concat (mojo-root) "/app"))
       (file-exists-p (concat (mojo-root) "/index.html"))))

(defun mojo-read-json-file (filename)
  "Parse the JSON in FILENAME and return the result."
  (save-excursion
    (let ((origbuffer (current-buffer))
	  (filebuffer (find-file-noselect filename)))
      (set-buffer filebuffer)
      (let ((text (buffer-string)))
	(switch-to-buffer origbuffer)
        (json-read-from-string text)))))

(defun mojo-app-version ()
  "Parse the project version from the appinfo.json file in `MOJO-ROOT'."
  (when (mojo-project-p)
    (let ((appinfo (mojo-read-json-file (concat (mojo-root) "/appinfo.json"))))
      (cdr (assoc 'version appinfo)))))

(defun mojo-app-id ()
  "Parse the project id from the appinfo.json file in `MOJO-ROOT'."
  (when (mojo-project-p)
    (let ((appinfo (mojo-read-json-file (concat (mojo-root) "/appinfo.json"))))
      (cdr (assoc 'id appinfo)))))

(defun mojo-app-title ()
  "Parse the project title from appinfo.json."
  (when (mojo-project-p)
    (let ((appinfo (mojo-read-json-file (concat (mojo-root) "/appinfo.json"))))
      (cdr (assoc 'title appinfo)))))

(defun mojo-informal-app-id ()
  "Parse the project title from appinfo.json and remove all non alphanumeric
   characters."
  (let ((title (downcase (mojo-app-title))))
    (replace-regexp-in-string "[^a-z0-9]" "" title)))

(defun mojo-package-filename ()
  "Get the package filename for the specified application."
  (format "%s/%s_%s_all.ipk" (expand-file-name mojo-build-directory)
	  (mojo-app-id) (mojo-app-version)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; app listing and completion ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar *mojo-app-cache-filename* nil)
(defun mojo-app-cache-file (&optional force-reload)
  "Cache the list of applications in a temporary file.  Return the filename."
  (when (or force-reload
	  (not *mojo-app-cache-filename*))
    (setq *mojo-app-cache-filename* (make-temp-file "mojo-app-list-cache"))
    (save-excursion
      (let ((buffer (find-file-noselect *mojo-app-cache-filename*))
	    (apps (mojo-fetch-app-list)))
	(set-buffer buffer)
	(insert (mojo-string-join "\n" apps))
	(basic-save-buffer)
	(kill-buffer buffer))))
  *mojo-app-cache-filename*)

(defvar *mojo-app-id* nil
  "Most recently used application id.")

(defvar *mojo-package-filename* nil
  "Most recently used package file.")

(defvar *mojo-app-history* nil
  "List of the most recently used application ids.")

;; cache expires hourly by default
(defvar *mojo-app-cache-ttl* 3600
  "The minimum age of a stale cache file, in seconds.")

(defvar *mojo-package-history* nil
  "List of the most recently used package filenames.")

;; this is from rails-lib.el in the emacs-rails package
(defun mojo-string-join (separator strings)
  "Join all STRINGS using SEPARATOR."
  (mapconcat 'identity strings separator))

(defun mojo-blank (thing)
  "Return T if THING is nil or an empty string, otherwise nil."
  (or (null thing)
      (and (stringp thing)
           (= 0 (length thing)))))

(defun mojo-read-root ()
  "Get the path to a Mojo application, prompting with completion and
  history."
  (read-file-name "Mojo project: " (expand-file-name (concat mojo-project-directory "/"))))

(defun mojo-read-package-filename ()
  "Get the filename of a packaged application, prompting with completion and
  history.

The app id is stored in *mojo-package-filename* unless it was blank."
  (let* ((default (or *mojo-package-filename*
		      (mojo-package-filename)))
         (package (read-file-name (format "Package file (default: %s): " default)
				  (concat mojo-build-directory "/") default t)))
    (setq *mojo-package-filename* (mojo-filename package))
    (expand-file-name package)))

(defun mojo-read-app-id (&optional prompt)
  "Get the id of an existing application, prompting with completion and
  history.

The app id is stored in *mojo-app-id* unless it was blank."
  (let* ((default (or *mojo-app-id* (mojo-app-id)))
         (prompt (or prompt
		     (format "App id (default: %s): " default)))
         (app-id (completing-read prompt
				  (mojo-app-list t)
				  nil
				  t
				  nil
				  '*mojo-app-history*
				  default)))
    (when (mojo-blank app-id)
      (setq app-id (mojo-app-id)))
    (setq *mojo-app-id* app-id)
    app-id))

(defun mojo-app-list (&optional fetch-if-missing-or-stale)
  "Get a list of installed Mojo applications."
  (cond ((and (file-readable-p (mojo-app-cache-file))
              (not (mojo-app-cache-stale-p)))
         (save-excursion
           (let* ((buffer (find-file (mojo-app-cache-file)))
                  (apps (split-string (buffer-string))))
             (kill-buffer buffer)
             apps)))
        (fetch-if-missing-or-stale
         (mojo-app-cache-file t) ;; force reload
         (mojo-app-list)) ;; guaranteed cache hit this time
        (t nil)))

(defun mojo-fetch-app-list ()
  "Fetch a fresh list of all applications."
  (mojo-ensure-emulator-is-running)
  (let* ((raw-list (nthcdr 7 (split-string (mojo-cmd-to-string "palm-install" (list "--list")))))
	 (apps (list))
	 (appname-regex "^[^0-9][^.]+\\(\\.[^.]+\\)+$")
	 (item (pop raw-list)))
    (while item
	(if (string-match appname-regex item) ;; liberal regex for simplicity
	  (push item apps)
	(print (concat "discarding " item)))
	(setq item (pop raw-list)))
    (nreverse apps)))

(defun mojo-app-cache-stale-p ()
  "Non-nil if the cache in `MOJO-APP-CACHE-FILE' is more than
  *mojo-app-cache-ttl* seconds old.

If the cache file does not exist then it is considered stale."
  (or (null (file-exists-p (mojo-app-cache-file)))
      (let* ((now (float-time (current-time)))
             (last-mod (float-time (sixth (file-attributes
             (mojo-app-cache-file)))))
             (age (- now last-mod)))
        (> age *mojo-app-cache-ttl*))))

(defun mojo-invalidate-app-cache ()
  "Delete the app list cache."
  (delete-file (mojo-app-cache-file)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; switch to files easily  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar *mojo-switch-suffixes*
  '(("-assistant.js" . mojo-switch-to-view)
    ("-scene.html"   . mojo-switch-to-assistant)
    (".html"         . mojo-switch-to-next-view)
    (""              . mojo-switch-to-appinfo)))

;;* interactive
(defun mojo-switch-to-appinfo ()
  (interactive)
  (find-file (concat (mojo-root) "/appinfo.json")))

;;* interactive
(defun mojo-switch-to-index ()
  (interactive)
  (find-file (concat (mojo-root) "/index.html")))

;;* interactive
(defun mojo-switch-to-sources ()
  (interactive)
  (find-file (concat (mojo-root) "/sources.json")))

;;* interactive
(defun mojo-switch-to-stylesheet ()
  (interactive)
  (let* ((stylesheet-dir (concat (mojo-root) "/stylesheets"))
	 (path (concat stylesheet-dir "/"
		       (mojo-informal-app-id) ".css")))
    (when (not (file-exists-p path))
      (setq path (car (mojo-filter-paths (directory-files stylesheet-dir t)))))
    (find-file path)))

(defun mojo-parent-directory-name (path)
  (mojo-filename (mojo-parent-directory path)))

(defun mojo-scene-name-from-assistant ()
  (let ((path (buffer-file-name)))
    (and (string= "assistants" (mojo-parent-directory-name path))
	 (substring (mojo-filename path) 0 (- 0 (length "-assistant.js"))))))

(defun mojo-scene-name-from-view ()
  (let ((path (buffer-file-name)))
    (and (string= "views" (mojo-parent-directory-name (mojo-parent-directory path)))
	 (mojo-parent-directory-name path))))

;;* interactive
(defun mojo-switch-file-dwim ()
  "Determine if the current buffer is visiting a file with known
   relationships. Try to find the 'best' choice and switch to it.

   This does what I (sjs) mean by default, so change
   *mojo-switch-suffixes* if you want different behaviour."
  (interactive)
  (let* ((path (buffer-file-name))
	 (suffixes (copy-list *mojo-switch-suffixes*))
	 (switch-function
	  (catch 'break
	    (dolist (pair suffixes nil)
	      (let ((suffix (car pair))
		    (function (cdr pair)))
		(when (string= suffix (substring path (- 0 (length suffix))))
		  (throw 'break function)))))))
    (when switch-function
      (call-interactively switch-function))))

;;* interactive
(defun mojo-switch-to-view ()
  (interactive)
  (when (mojo-project-p)
    (let ((scene-name (mojo-scene-name-from-assistant)))
      (find-file (concat (mojo-root)
			 "/app/views/" scene-name "/"
			 scene-name "-scene.html")))))

(defun mojo-ignored-path (path)
  (let ((filename (mojo-filename path)))
    (or (string= (substring filename 0 1) ".")
	(and (string= (substring filename 0 1) "#")
	   (string= (substring filename -1) "#")))))

(defun mojo-filter-paths (all-paths)
  (let ((wanted-paths (list)))
    (dolist (path all-paths wanted-paths)
      (unless (mojo-ignored-path path)
	(setq wanted-paths (cons path wanted-paths))))
    (reverse wanted-paths)))

(defun mojo-index (elem list)
  (catch 'break
    (let ((index 0))
      (dolist (path list index)
	(incf index)
	(when (string= path elem)
	  (throw 'break index))))))

;;* interactive
(defun mojo-switch-to-next-view ()
  (interactive)
  (when (mojo-project-p)
    (let* ((scene-name (mojo-scene-name-from-view))
	   (view-dir (concat (mojo-root) "/app/views/" scene-name))
	   (view-files (mojo-filter-paths (directory-files view-dir t)))
(mojo-filter-paths (directory-files (concat (mojo-root) "/app/views/" (mojo-scene-name-from-view)) t))
	   (index (mojo-index (buffer-file-name) view-files))
	   (filename (nth (mod index (length view-files)) view-files)))
      (find-file filename))))

;;* interactive
(defun mojo-switch-to-assistant ()
  (interactive)
  (let ((scene-name (mojo-scene-name-from-view)))
    (when (and (mojo-project-p)
	       scene-name)
      (find-file (concat (mojo-root)
			 "/app/assistants/" scene-name "-assistant.js")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;* lowlevel luna
(defun mojo-luna-send (url data)
  "Send something through luna.

Luna-send is a program to send things like incoming calls, GPS status, SMS,
etc.  to your emulator.

This is a low level Emacs interface to luna-send.
URL is the luna url, and DATA is the data."
  (mojo-cmd "luna-send" (list "-n" "1" url data)))

(defvar *mojo-target* "tcp"
  "Used to specify the target platform, \"usb\" for the device
  and \"tcp\" for the emulator.  Deaults to \"tcp\".")

(defun mojo-emulator-running-p ()
  "Determine if the webOS emulator is running or not.

This command only works on Unix-like systems."
  (= 0 (shell-command "ps x | fgrep 'Palm SDK' | fgrep -v fgrep >/dev/null 2>&1")))

(defun mojo-emulator-responsive-p ()
  "Determine if the webOS emulator is able to respond to commands yet
 (i.e. if it's done booting)."
  (= 0 (shell-command "palm-install -d tcp --list >/dev/null 2>&1")))

(defun mojo-path-to-cmd (cmd)
  "Return the absolute path to a Mojo SDK command line program."
  (case system-type
    ((windows-nt) (concat mojo-sdk-directory "/bin/" cmd ".bat"))
    (t (concat mojo-sdk-directory "/bin/" cmd))))

;;* lowlevel cmd
(defun mojo-cmd (cmd args)
  "General interface for running mojo-sdk commands.

CMD is the name of the command (without path or extension) to execute.
 Automagically shell quoted.
ARGS is a list of all arguments to the command.
 These arguments are NOT shell quoted."
  (let ((cmd (mojo-path-to-cmd cmd))
	(args (mojo-string-join " " args)))
    (if mojo-debug (message "running %s with args %s " cmd args))
    (shell-command (concat cmd " " args))))

;;* lowlevel cmd
(defun mojo-cmd-with-target (cmd args &optional target)
  "General interface for running mojo-sdk commands that accept a target device.

CMD is the name of the command (without path or extension) to
 execute.  Automagically shell quoted.  ARGS is a list of all
 arguments to the command.  These arguments are NOT shell quoted.
 TARGET specifies the target device, \"tcp\" or \"usb\"."
  (let ((args (cons "-d" (cons (or target *mojo-target*) args))))
    (mojo-cmd cmd args)))

;;* lowlevel cmd
(defun mojo-cmd-to-string (cmd args &optional target)
  "General interface for running mojo-sdk commands and capturing the output
   to a string.

CMD is the name of the command (without path or extension) to execute.
 Automatically shell quoted.
ARGS is a list of all arguments to the command.
 These arguments are NOT shell quoted."
  (let ((cmd (mojo-path-to-cmd cmd))
	(args (concat "-d " (or target *mojo-target*) " "
		       (mojo-string-join " " args))))
    (if mojo-debug (message "running %s with args %s " cmd args))
    (shell-command-to-string (concat cmd " " args))))

(provide 'mojo)


;;; mojo ends here
