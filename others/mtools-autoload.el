
;;;### (autoloads (mtools-file-name-handler) "mtools" "mtools.el"
;;;;;;  (19136 10794))
;;; Generated autoloads from mtools.el

(defconst mtools-file-name-prefix-regex "^/mtools/[a-z]:")

(add-to-list (quote file-name-handler-alist) (cons mtools-file-name-prefix-regex (function mtools-file-name-handler)) nil (lambda (x y) (equal (car x) (car y))))
(makunbound 'mtools-file-name-prefix-regex)

(defconst mtools-handlers-alist (quote ((file-exists-p . mtools-file-exists-p) (file-readable-p . mtools-file-exists-p) (file-writable-p . mtools-file-writable-p) (file-executable-p . mtools-file-directory-p) (file-symlink-p lambda (&rest args) nil) (file-directory-p . mtools-file-directory-p) (file-attributes . mtools-file-attributes) (insert-file-contents . mtools-insert-file-contents) (insert-directory . mtools-insert-directory) (copy-file . mtools-copy-file) (rename-file . mtools-rename-file) (delete-file . mtools-delete-file) (delete-directory . mtools-delete-directory) (make-directory-internal . mtools-make-directory-internal) (write-region . mtools-write-region) (directory-files . mtools-directory-files) (dired-compress-file . mtools-compress-file) (file-name-completion . mtools-file-name-completion) (file-name-all-completions . mtools-file-name-all-completions))))

(autoload (quote mtools-file-name-handler) "mtools" "\
Invoke mtool's file name handler for OPERATION.
First arg specifies the OPERATION, second arg is a list of arguments to
pass to the OPERATION.

To begin with, try \\[find-file] /mtools/a: \\[newline]
\(or any other drive you desire). 
This brings up the `dired' mode.
Many `dired' operations are supported: \\<mtools-dired-map>(keystrokes in parentheses)
  * open (\\[dired-find-file]) or (\\[dired-view-file])
  * copy (\\[dired-do-copy])
  * rename/move (\\[dired-do-rename])
  * delete (\\[dired-flag-file-deletion]) followed by (\\[dired-do-flagged-delete])
  * create directory (\\[dired-maybe-insert-subdir])
  * remove directory (\\[dired-flag-file-deletion])
  * check/change attributes (\\[mtools-do-mattrib])
  * query file type (\\[mtools-show-file-type])
  * change sort order (\\[mtools-change-dired-sort-order])
  * compress/uncompress (\\[dired-do-compress])
\\<global-map>
You can open a file directly by append the pathname to ``/mtools/a:/''
\(e.g. \\[find-file] /mtools/a:/readme.txt \\[newline])
and save it with \\[save-buffer] when you're done with the editing.
It works just like ordinary files.
You can also hit \\<minibuffer-local-filename-completion-map>\\[minibuffer-complete]\\<global-map> to let Emacs complete the file name,
as long as you've typed beyond the drive letter and `:/'.

By default, the `mtools' utilities map drive a: to the first
floppy drive (e.g. `/dev/fd0' on Linux),
and b: to the second drive.
To customize the drive mappings
\(e.g. to access a USB thumb drive, or a [V]FAT file image),
edit /etc/mtools.conf (per system) or ~/.mtoolsrc (per user).
See the info node `(mtools)' for details.

`mtools' makes access to [V]FAT filesystems transparent via
the GNU `mtools' utility
\(see URL `http://www.gnu.org/software/mtools/mtools.html').
It's advantage over mounting via the usual Unix way include:
* usable by unprivileged users without `sudo' or similar utilities,
  as long as the accessed device node grants permissions to the user;
* no need to unmount -- mtools holds the device for its whole transaction
  and releases it when done;  hence, user won't forget to unmount;
  no need to do a ``safely remove device'' operation

\(fn OPERATION &rest ARGS)" nil nil)

(put (quote mtools-file-name-handler) (quote operations) (mapcar (function car) mtools-handlers-alist))
(makunbound 'mtools-handlers-alist)

;;;***
