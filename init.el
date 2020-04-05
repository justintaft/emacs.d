;Ensure certificates are checked
(setq network-security-level 'high)


;Check emacs version to prevent unsafe HTTPS connections being made,
;due to default network security manager settings.
(unless (>= emacs-major-version ) 
    (error "Old version of emacs detected. Network security manager isn't implemented. Unsafe to download packages over HTTPS."))


(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(package-initialize)

(setq package-enable-at-startup nil)

;update packages
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))


(eval-when-compile
  (require 'use-package))

;(require 'diminish)
;(require 'bind-key)

(defun apply-function-to-selected-region (thefn) 
       "Return string containing selected region with line numbers"
       (save-excursion (goto-char (region-beginning)))
       (let ((line-number (- (line-number-at-pos (region-beginning)) 1)))
       	    (string-join
	    	     (mapcar (lambda (line)
		                 (progn (setq line-number (+ 1 line-number))
                                 (funcall thefn (number-to-string line-number) line)))
			     (nbutlast (split-string (buffer-substring (region-beginning) (region-end)) "\n") 1))
		     "\n")
		     ))

(defun linenumber-name-file-number-lines-and-copy-to-kill-buffer ()
  "Add string to kill buffer consiting of file name and region with line numbers."
  (interactive)
  (kill-new (concat "From *"
		    (file-relative-name (buffer-file-name) (projectile-project-root))
		    "*:\n\nbc. "
		    (apply-function-to-selected-region (lambda (line-number line) (concat line-number " " line)))))
  (deactivate-mark))

(defun code-coverage-mark-as-read ()
    (interactive)
    (save-excursion
      (if (not mark-active)
	  (let (p1 p2)
	    (forward-line 0)
	    (setq p1 (line-beginning-position))
	    (forward-line 1)
	    (setq p2 (line-beginning-position))
	    (goto-char p1)
	    (push-mark p2)
	    (setq mark-active t)))
      

      
      (write-region (apply-function-to-selected-region (lambda (line-number line) (concat "100: " line-number ": " line "\n")))
      		nil
      		(concat buffer-file-name ".gcov")
      		'append))
    (setq mark-active nil)
    (cov-update))

             


  
  
; auto update packages once a day
(use-package auto-package-update
   :ensure t
   :config
   (setq auto-package-update-interval 1))


(defun jt-on-macos-p ()
  "Check if current system is on osx"
  (string-equal system-type "darwin"))

(defun jt-on-linux-p ()
  "Check if emacs is running on linux"
  (string-equal system-type "gnu/linux"))


;Ping cloudflare DNS to see if internet is up. Does not use domain
;name as name might not be able to be resolved.
(defun internet-up-p ()
    (= 0 (call-process "ping" nil nil nil "-c" "1" "-W" (if (jt-on-macos-p) "1000" "1") "1.1.1.1") ))

;If we don't have internet, don't bother updating packages.
(defun apu--get-permission-to-update-p () 
  (internet-up-p))
(auto-package-update-maybe)


;;org mode
(use-package org :ensure t :init (setq org-startup-with-inline-images 1))
  


;;Clojure - re-constructs namespace for automatic imports
;Slamhound master is currently broken, due to cider updates.
;(use-package slamhound :ensure t )

;(custom-set-variables
; ;; custom-set-variables was added by Custom.
; ;; If you edit it by hand, you could mess it up, so be careful.
; ;; Your init file should contain only one such instance.
; ;; If there is more than one, they won't work right.
; '(ansi-color-faces-vector
;   [default default default italic underline success warning error])
; '(custom-enabled-themes (quote (tango-dark)))
; '(custom-safe-themes
;   (quote
;    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" default)))
; '(package-selected-packages
;   (quote
;    (nyan-mode nyan-cat cov xcscope golden-ratio neotree helm-ag helm-projectile helm multi-term clj-refactor ## 0blayout cider ag php-mode rainbow-identifiers rainbow-delimiters evil-magit magit-evil magit evil-tabs company-flx use-package key-chord evil-leader company)))
; '(show-paren-mode t))
;(custom-set-faces
; ;; custom-set-faces was added by Custom.
; ;; If you edit it by hand, you could mess it up, so be careful.
; ;; Your init file should contain only one such instance.
; ;; If there is more than one, they won't work right.
; )




(show-paren-mode 1)
(setq show-paren-delay 0)



(load-theme 'tango-dark)


;(defface flyspell-incorrect
;  '((((supports :underline (:style wave)))
;     :underline (:style wave :color "Red1"))
;    (t
;     :underline t :inherit error))
;  "Flyspell face for misspelled words."
;  :version "24.4"
;  :group 'flyspell)

;automatically create screens as needed...such as vim tabn
(defmacro elscreen-create-automatically (ad-do-it)
 (if (not (elscreen-one-screen-p))
	ad-do-it
    (elscreen-create)
    (elscreen-notify-screen-modification 'force-immediately)
    (elscreen-message "New screen is automatically created")))

(defadvice elscreen-next (around elscreen-create-automatically activate)
(elscreen-create-automatically ad-do-it))

(defadvice elscreen-previous (around elscreen-create-automatically activate)
(elscreen-create-automatically ad-do-it))

(defadvice elscreen-toggle (around elscreen-create-automatically activate)
(elscreen-create-automatically ad-do-it))




;configure that mode line
(defun shorten-directory (dir max-length)
  "Show up to `max-length' characters of a directory name `dir'."
  (let ((path (reverse (split-string (abbreviate-file-name dir) "/")))
               (output ""))
       (when (and path (equal "" (car path)))
         (setq path (cdr path)))
       (while (and path (< (length output) (- max-length 4)))
         (setq output (concat (car path) "/" output))
         (setq path (cdr path)))
       (when path
         (setq output (concat ".../" output)))
       output))

(defvar mode-line-directory
  '(:propertize
    (:eval (if (buffer-file-name) (concat " " (shorten-directory default-directory 100)) " "))
                face mode-line-directory)
  "Formats the current directory.")
(put 'mode-line-directory 'risky-local-variable t)

(setq-default mode-line-format
	      '("%e"
		mode-line-front-space
		mode-line-client
		mode-line-modified
		mode-line-directory
		mode-line-buffer-identification
		mode-line-position
		evil-mode-line-tag
		global-mode-string
		""
		mode-line-modes
		mode-line-misc-info
		mode-line-end-spaces
		))

(setq cscope-option-other '("-d"))

(defun my-paste-image-from-clipboard ()
  "Take a screenshot into a time stamped unique-named file in the same 
directory as the org-buffer and insert
a link to this file."
  (interactive)
  (setq tilde-buffer-filename
        (replace-regexp-in-string "/" "\\" (buffer-file-name) t t))
  (setq filename
        (concat
         (make-temp-name
          (concat tilde-buffer-filename
                  "_"
                  (format-time-string "%Y%m%d_%H%M%S_")) ) ".jpg"))
  ;; Linux: ImageMagick: (call-process "import" nil nil nil filename)
  ;; Windows: Irfanview
  (call-process "/usr/local/bin/pngpaste" nil nil nil filename)
  (insert (concat "[[file:" filename "]]"))
  (org-display-inline-images)) 



(defun load-directory (dir)
  (let ((load-it (lambda (f)
		   (load-file (concat (file-name-as-directory dir) f)))
		 ))
    (mapc load-it (directory-files dir nil "\\.el$"))))
;;(load-directory "~/.emacs.d/config-elisp")

;Speed up loading of emacs by setting high threshold for garbage collection.
(let ((gc-cons-threshold most-positive-fixnum))
      (org-babel-load-file "~/.emacs.d/config.org"))





;;shift-return opens results into new window
(defun my-buffer-split-and-display ()
    (interactive)
    (let ((display-buffer-function 'my-split-and-display))
    (Buffer-menu-this-window)))



(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("c5d320f0b5b354b2be511882fc90def1d32ac5d38cccc8c68eab60a62d1621f2" "aa0a998c0aa672156f19a1e1a3fb212cdc10338fb50063332a0df1646eb5dfea" default)))
 '(gnutls-trustfiles
   (quote
    ("/etc/ssl/certs/ca-certificates.crt" "/etc/pki/tls/certs/ca-bundle.crt" "/etc/ssl/ca-bundle.pem" "/usr/ssl/certs/ca-bundle.crt" "/usr/local/share/certs/ca-root-nss.crt")))
 '(line-number-mode nil)
 '(org-agenda-files (quote ("/tmp/what.txt")))
 '(package-selected-packages
   (quote
    (flycheck highlight-indent-guides emacs-pass-simple package-lint multiple-cusors mutliple-cusors parinfer minimap ob-go emaacspeak emaacsspeak ivy swyper swiper emacs-lsp lsp lsp-mode yascroll go-mode yasnippet doom-themes spacemacs-theme csharp-mode sml-modeline ert-async wcheck-mode wcheck auto-package-update markdown-mode markdown xcscope ag nyan-mode rainbow-delimiters cider company-flx company multi-term neotree helm-projectile helm-ag helm golden-ratio paredit evil-magit magit key-chord use-package evil-tabs evil-leader))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(flyspell-duplicate ((t (:foreground "#ff7070" :weight bold :underline (:color "#ff0000" :style wave)))))
 '(flyspell-incorrect ((t (:foreground "#ff7070" :weight bold :underline (:color "#ff0000" :style wave))))))
