;;; alexfox --- Aleksei Lunacharskii personal emacs configuration
;;; Commentary:
;;; This file is how I adapted myself to Emacs for every day use

(require 'package)

;;; Code:

(disable-theme 'zenburn)

(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https"))
       (url ))
  (add-to-list 'package-archives
               (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;; (add-to-list 'package-archives
  ;; (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  )

;; Check/install/require packages

(defun ensure-package-installed (packages)
  "Assure every package is installed, ask for installation if it’s not.
PACKAGES - packages to check

Return a list of installed packages or nil for every skipped package."
  (mapcar
   (lambda (package)
     ;; (package-installed-p 'evil)
     (if (package-installed-p package)
         nil
       (if (y-or-n-p (format "Package %s is missing.  Install it? " package))
           (package-install package)
         package)))
   packages))

;; make sure to have downloaded archive description.
;; Or use package-archive-contents as suggested by Nicolas Dudebout
(or (file-exists-p package-user-dir)
    (package-refresh-contents))

;; activate installed packages
(package-initialize)

(ensure-package-installed '(cider
                            smartparens
                            git
                            indium
                            evil
                            tern
                            tide
                            web-mode
                            markdown-mode
                            rainbow-delimiters
                            company
                            eclim))

(require 'rainbow-delimiters)
(require 'evil)
(require 'tide)

;; Custom function

(defun format-defun ()
  "IntelliJ IDEA-like formatting for current defun."
  (interactive)
  (let ((c (point)))
    (beginning-of-defun)
    (set-mark (point))
    (end-of-defun)
    (indent-region (mark) (point))
    (deactivate-mark)
    (goto-char c)))

(global-set-key (kbd "M-s-¬") #'format-defun)

;; Terminal-like buffer switching

(global-set-key (kbd "s-{") #'previous-buffer)
(global-set-key (kbd "s-}") #'next-buffer)

;; query-replace current word

(defun query-replace-current (replace-str)
  "Replace the s-exp under cursor.

REPLACE-STR string to replace with"

  (interactive "sDo query-replace current word with: ")
  (paredit-forward)
  (let ((end (point)))
    (paredit-backward)
    (kill-ring-save (point) end)
    (goto-char (point-min))
    (query-replace (current-kill 0) replace-str)))

(global-set-key (kbd "s-r") #'query-replace-current)

(defun query-search-current ()
  "Search the s-exp under cursor."
  (interactive)
  (paredit-forward)
  (let ((end (point)))
    (paredit-backward)
    (kill-ring-save (point) end)
    (swiper (current-kill 0 t))
    ))

(defun query-search-current-in-project ()
  "Search the s-exp under cursor using projectile ag."
  (interactive)
  (paredit-forward)
  (let ((end (point)))
    (paredit-backward)
    (kill-ring-save (point) end)
    (helm-projectile-ag "-sa")
    ))

(global-set-key (kbd "s-3") #'query-search-current)
(global-set-key (kbd "M-s-£") #'query-search-current-in-project)

;; Save all tempfiles in $TMPDIR/emacs$UID/
(defconst emacs-tmp-dir (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))
(setq backup-directory-alist
      `((".*" . ,emacs-tmp-dir)))
(setq auto-save-file-name-transforms
      `((".*" ,emacs-tmp-dir t)))
(setq auto-save-list-file-prefix
      emacs-tmp-dir)

(menu-bar-mode -1)

(global-set-key [M-tab] #'company-complete)

(global-set-key (kbd "<f10>") #'evil-local-mode)
(global-set-key (kbd "<f9>") #'linum-mode)
(global-set-key (kbd "<f8>") (lambda ()
                               (interactive)
                               (whitespace-toggle-options 'lines)))

(add-hook 'after-init-hook 'global-company-mode)
;; (add-hook 'after-init-hook 'global-whitespace-mode)

;; adjust indents for web-mode to 2 spaces
(defun my-web-mode-hook ()
  "Hooks for Web mode.  Adjust indent."
  ;;; http://web-mode.org/
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2))
(add-hook 'web-mode-hook  'my-web-mode-hook)

(require 'indium)

(defun my-js-mode-hook ()
  "Enable indium, global keybindings etc."
  (indium-interaction-mode)
  (local-set-key (kbd "<s-return>") #'indium-eval-buffer)
  (local-set-key (kbd "<C-M-SPC>") #'sp-mark-sexp)
  (tern-mode t))

(setq-default indent-tabs-mode nil)
(setq js-indent-level 2)
(setq tab-width 2)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

(add-hook 'coffee-mode-hook
          (lambda ()
            (add-hook 'after-save-hook (lambda () (projectile-run-project nil)))
            ))

(add-hook 'js2-mode-hook #'my-js-mode-hook)

(eval-after-load 'company
    '(add-to-list 'company-backends 'company-tern))

(defun my-frame-config ()
  "Set font size and full screen frame."
  ;; Set main frame size
  (when window-system
    ;;  (set-frame-size (selected-frame) 171 47)
    (add-to-list 'default-frame-alist '(font . "Menlo-18"))
    (add-to-list 'default-frame-alist '(fullscreen . maximized))
    (set-frame-font "Menlo-18" nil t))
  )

(add-hook 'window-setup-hook 'my-frame-config)

(evil-mode 0)

(global-set-key (kbd "<C-M-SPC>") #'sp-mark-sexp)

(add-hook 'clojure-mode-hook #'smartparens-strict-mode)
(add-hook 'clojure-mode-hook #'rainbow-delimiters-mode)

(show-paren-mode 1)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(after-save-hook nil)
 '(cider-cljs-lein-repl
   "(do (require 'figwheel-sidecar.repl-api) (figwheel-sidecar.repl-api/start-figwheel!) (figwheel-sidecar.repl-api/cljs-repl))")
 '(coffee-tab-width 2)
 '(compilation-read-command nil)
 '(custom-safe-themes
   (quote
    ("b8c5adfc0230bd8e8d73450c2cd4044ad7ba1d24458e37b6dec65607fc392980" "db510eb70cf96e3dbd48f5d24de12b03db30674ea0853f06074d4ccf7403d7d3" "da8e6e5b286cbcec4a1a99f273a466de34763eefd0e84a41c71543b16cd2efac" "05d009b7979e3887c917ef6796978d1c3bbe617e6aa791db38f05be713da0ba0" "5c83b15581cb7274085ba9e486933062652091b389f4080e94e4e9661eaab1aa" default)))
 '(grep-find-ignored-directories
   (quote
    ("SCCS" "RCS" "CVS" "MCVS" ".svn" ".git" ".hg" ".bzr" "_MTN" "_darcs" "{arch}" ".chrome" "build")))
 '(initial-frame-alist (quote ((fullscreen . maximized))))
 '(js2-strict-missing-semi-warning nil)
 '(js2-strict-trailing-comma-warning nil)
 '(package-selected-packages
   (quote
    (pinentry coffee-mode cider karma projectile exec-path-from-shell find-file-in-project markdown-mode groovy-mode js2-mode json-mode web-mode company-tern tern auctex typescript-mode tide magit flycheck color-theme-modern indium git yaml-mode cider-eval-sexp-fu smartparens rainbow-delimiters evil)))
 '(safe-local-variable-values
   (quote
    ((ffip-patterns "*.html" "*.js" "*.css" "*.java" "*.xml" "*.js" "*.cljs" "*.clj" "*.json" "*.sh" "*.el")
     (ffip-find-options . "-not -iwholename './target/*'")
     (ffip-find-options . "-not -iwholename './out/*' -not -iwholename './prod/*' -not -iwholename './target/*' -not -iwholename './dist/*' -not -wholename './coverage/*'")
     (ffip-find-options . "-not -iwholename 'out/*' -not -iwholename 'prod/*' -not -iwholename 'target/*' -not -iwholename '*/dist/*' -not -wholename 'coverage/*'")
     (ffip-find-options . "-not -iwholename '*/out/*' -not -iwholename '*/prod/*' -not -iwholename '*/target/*' -not -iwholename '*/dist/*' -not -wholename '*coverage*'")
     (ffip-patterns "*.html" "*.js" "*.css" "*.java" "*.xml" "*.js" "*.cljs" "*.clj" "*.json")
     (ffip-find-options . "-not -iwholename '*/out/*' -not -iwholename '*/prod/*' -not -iwholename '*/target/*' -not -iwholename '*/dist/*'")
     (ffip-find-options . "-not -iwholename '*/out/*' -not -iwholename '*/prod/*' -not -iwholename '*/target/*'")
     (ffip-find-options . "-not -iwholename '*/out/*'")
     (ffip-find-options . "'*/out/*'"))))
 '(send-mail-function (quote smtpmail-send-it)))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Use mac spotlight find
(setq locate-command "mdfind")

;; JS/JSX ESlint setup
;; http://codewinds.com/blog/2015-04-02-emacs-flycheck-eslint-jsx.html
;; use web-mode for .jsx files
(add-to-list 'auto-mode-alist '("\\.jsx$" . web-mode))

;; http://www.flycheck.org/manual/latest/index.html
(require 'flycheck)

;; turn on flychecking globally
(add-hook 'after-init-hook #'global-flycheck-mode)

;; disable jshint since we prefer eslint checking
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(javascript-jshint javascript-standard)))

;; use eslint with web-mode for jsx files
(flycheck-add-mode 'javascript-eslint 'web-mode)

;; customize flycheck temp file prefix
(setq-default flycheck-temp-prefix ".flycheck")

;; disable json-jsonlist checking for json files
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(json-jsonlist)))

;; YASnippet

(require 'yasnippet)
(yas-global-mode 1)

;; use local eslint from node_modules before global
;; http://emacs.stackexchange.com/questions/21205/flycheck-with-file-relative-eslint-executable
(defun my/use-eslint-from-node-modules ()
  (let* ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "node_modules"))
         (eslint (and root
                      (expand-file-name "node_modules/.bin/eslint"
                                        root))))
    (when (and eslint (file-executable-p eslint))
      (setq-local flycheck-javascript-eslint-executable eslint))))
(add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules)
;; Typescript setup

(defun setup-tide-mode ()
  "Customize typescript mode."
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  ;; company is an optional dependency. You have to
  ;; install it separately via package-install
  ;; `M-x package-install [ret] company`
  (company-mode +1))

;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

(add-hook 'typescript-mode-hook #'setup-tide-mode)

;; Turn off mouse interface early in startup to avoid momentary display
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen please
(setq inhibit-startup-message t)

;; Find files in project

(global-set-key (kbd "s-N") 'projectile-find-file)

;; Font lock

(global-font-lock-mode t)

;; Eshell fast spawn

(global-set-key (kbd "s-b s-s") #'projectile-run-eshell)

(defun query-db ()
  "Run a query-db via cider."
  (interactive)
  (save-buffer)
  (cider-interactive-eval "(require 'jdbc.query) (jdbc.query/query-db)"))

(global-set-key (kbd "s-b s-q") #'query-db)

(defun show-file-name ()
  "Show the full path file name in the minibuffer."
  (interactive)
  (message (buffer-file-name)))

(global-set-key (kbd "s-b s-p") 'show-file-name)

(global-set-key (kbd "s-b s-f") 'find-file-at-point)

(defun open-github ()
  "Opens current line on github.com."
  (interactive)
  (let ((was-active t))
    (when (not mark-active)
      (setq was-active nil)
      (set-mark (point))
      (forward-char))
    (open-github-from-here)
    (when (not was-active)
      (set-mark-command 0)
      )))

(global-set-key (kbd "s-b s-g") 'open-github)

;; Simple secrects

(add-to-list 'load-path "~/.emacs.d/alun/custom")

(require 'open-github-from-here)
(require 'simple-secrets)
(setq secret-password-file "~/passwd/.file.gpg")
(secret-load-keys)


(global-set-key (kbd "s-b s-p") #'secret-lookup-clipboard)

(secret-generate-password)

(require 'projectile)

;; Paredit
(require 'paredit)

(autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t)
(add-hook 'emacs-lisp-mode-hook       #'enable-paredit-mode)
(add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
(add-hook 'ielm-mode-hook             #'enable-paredit-mode)
(add-hook 'lisp-mode-hook             #'enable-paredit-mode)
(add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
(add-hook 'scheme-mode-hook           #'enable-paredit-mode)
(add-hook 'clojurescript-mode-hook    #'enable-paredit-mode)
(add-hook 'clojure-mode-hook          #'enable-paredit-mode)

;; web mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

;; Pinentry

(setenv "INSIDE_EMACS" (format "%s,comint" emacs-version))
(pinentry-start)

;; Don't remove trailing space in markdown

(add-hook 'gfm-mode-hook
          (lambda ()
            (setq-local
             prelude-clean-whitespace-on-save nil)))

;; Eshell ascii escapes stripping

(defvar my-ansi-escape-re
  (rx (or ?\233 (and ?\e ?\[))
      (zero-or-more (char (?0 . ?\?)))
      (zero-or-more (char ?\s ?- ?\/))
      (char (?@ . ?~))))

(defun my-nuke-ansi-escapes (beg end)
  (save-excursion
    (goto-char beg)
    (while (re-search-forward my-ansi-escape-re end t)
      (replace-match ""))))

(defun my-eshell-nuke-ansi-escapes ()
  (my-nuke-ansi-escapes eshell-last-output-start eshell-last-output-end))

(add-hook 'eshell-output-filter-functions 'my-eshell-nuke-ansi-escapes t)

;; Eclim

(require 'eclim)
(add-hook 'java-mode-hook 'eclim-mode)

;; Easy JSON

(defun format-js ()
  (interactive)
  (when (= (region-beginning) (region-end))
    (easy-mark))
  (shell-command-on-region (region-beginning) (region-end)
                           "js-beautify -"
                           nil
                           t)
  (js2-mode)
  (keyboard-quit))

(global-set-key (kbd "s-b s-j") #'format-js)

(defun load-curl (command)
  (interactive "sCommand: ")
  (let ((buff (generate-new-buffer "curl"))
        (right-command (string-join (list command " 2>/dev/null"))))
    (switch-to-buffer buff)
    (shell-command-on-region 1 (buffer-end 1)
                             right-command
                             nil
                             t))
  )

(global-set-key (kbd "s-b s-l") #'load-curl)

;; Delete line function

(defun remove-line ()
  "Remove the current line."
  (interactive)
  (crux-move-beginning-of-line 1)
  (kill-line)
  (kill-line)
  (indent-for-tab-command))

(global-unset-key (kbd "s-d"))
(global-set-key (kbd "s-d s-d") #'remove-line)

;; ES6 expression arrow funciton indentiation

(require 'js-align)
(add-hook 'js2-mode-hook 'js-align-mode)

;; https://github.com/purcell/exec-path-from-shell
;; only need exec-path-from-shell on OSX
;; this hopefully sets up path and other vars better
(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize)
  (message "Shell PATH is loaded"))

;; Done

(message "Welcome back hacking")

(provide 'alexfox)

;;; init.el ends here
