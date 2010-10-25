;; source files
(set @m_files     (filelist "^objc/.*.m$"))
(set @nu_files 	  (filelist "^nu/.*nu$"))

(set SYSTEM ((NSString stringWithShellCommand:"uname") chomp))
(case SYSTEM
      ("Darwin"
               (set @arch (list "x86_64" ))
               (set @cflags "-g -std=gnu99 -fobjc-gc -DDARWIN")
               (set @ldflags  "-framework Foundation -framework Nu -lcrypto")
	       ;; explicitly link the non-shared libs for portability
               (@ldflags appendString:" /usr/local/lib/libevent.a /usr/local/lib/libevent_core.a"))
      ("Linux"
              (set @arch (list "i386"))
              (set gnustep_flags ((NSString stringWithShellCommand:"gnustep-config --objc-flags") chomp))
              (set gnustep_libs ((NSString stringWithShellCommand:"gnustep-config --base-libs") chomp))
              (set @cflags "-g -std=gnu99 -DLINUX -I/usr/local/include #{gnustep_flags}")
              (set @ldflags "#{gnustep_libs} -lNu -levent -lcrypto"))
      (else nil))

;; framework description
(set @framework "Kurt")
(set @framework_identifier "nu.programming.kurt")
(set @framework_creator_code "????")
(set @framework_extra_install (do () (SH "sudo cp kurtd /usr/local/bin")))

(ifDarwin
         (set @public_headers (filelist "^objc/.*\.h$")))

(compilation-tasks)
(framework-tasks)

(task "default" => "framework")

(task "doc" is (SH "nudoc"))
