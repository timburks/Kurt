;; @file       kurt.nu
;; @discussion Nu components of the Kurt web server.
;; @copyright  Copyright (c) 2008-2009 Neon Design Technology, Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

;; Declare a get action.
(global get
        (macro get (path *body)
             `(((Kurt kurt) delegate)
               addHandlerWithHTTPMethod:"GET"
               path:,path
               block:(do (REQUEST) ,@*body))))

;; Declare a post action.
(global post
        (macro post (path *body)
             `(((Kurt kurt) delegate)
               addHandlerWithHTTPMethod:"POST"
               path:,path
               block:(do (REQUEST) ,@*body))))

;; Declare a put action.
(global put
        (macro put (path *body)
             `(((Kurt kurt) delegate)
               addHandlerWithHTTPMethod:"PUT"
               path:,path
               block:(do (REQUEST) ,@*body))))

;; Declare a delete action.
(global delete
        (macro delete (path *body)
             `(((Kurt kurt) delegate)
               addHandlerWithHTTPMethod:"DELETE"
               path:,path
               block:(do (REQUEST) ,@*body))))

;; Declare a 404 handler.
(global get-404 (macro get-404 (*body)
                     `(((Kurt kurt) delegate)
                       setDefaultHandlerWithBlock:(do (REQUEST) ,@*body))))

(class Kurt
     (set _kurt nil)
     (+ (id) kurt is
        (unless _kurt
                (set argv ((NSProcessInfo processInfo) arguments))
                (set argi 0)
                
                ;; if we're running as a nush script, skip the nush path
                (if (/(.*)nush$/ findInString:(argv 0))
                    (set argi (+ argi 1)))
                
                ;; skip the program name
                (set argi (+ argi 1))
                
                ;; the option(s) we need to set
                (set port 3000)
                (set localOnly NO)
                (set site nil)
                
                ;; process the remaining arguments
                (while (< argi (argv count))
                       (case (argv argi)
                             ("-p"        (set argi (+ argi 1)) (set port ((argv argi) intValue)))
                             ("--port"    (set argi (+ argi 1)) (set port ((argv argi) intValue)))
                             ("-l"        (set localOnly YES))
                             ("--local"   (set localOnly YES))
                             ("-s"        (set argi (+ argi 1)) (set site (argv argi)))
                             ("--site"    (set argi (+ argi 1)) (set site (argv argi)))
                             ("-v"        (Kurt setVerbose:YES))
                             ("--verbose" (Kurt setVerbose:YES))
                             (else (puts (+ "unknown option: " (argv argi)))
                                   (exit -1)))
                       (set argi (+ argi 1)))
                
                (set _kurt (Kurt bareKurt))
                
                (if site
                    ((_kurt delegate) configureSite:site))
                
                (unless (zero? (_kurt bindToAddress:(if localOnly
                                                        (then "127.0.0.1")
                                                        (else "0.0.0.0"))
                                      port:port))
                        (puts (+ "Unable to start service on port " port ". Is another server running?"))
                        (exit -1)))
        _kurt)
     
     (+ (void) run is
        ((Kurt kurt) run)))

(Kurt setMimeTypes:
      (dict "ai"    "application/postscript"
            "asc"   "text/plain"
            "avi"   "video/x-msvideo"
            "bin"   "application/octet-stream"
            "bmp"   "image/bmp"
            "class" "application/octet-stream"
            "cer"   "application/pkix-cert"
            "crl"   "application/pkix-crl"
            "crt"   "application/x-x509-ca-cert"
            "css"   "text/css"
            "dll"   "application/octet-stream"
            "dmg"   "application/octet-stream"
            "dms"   "application/octet-stream"
            "doc"   "application/msword"
            "dvi"   "application/x-dvi"
            "eps"   "application/postscript"
            "etx"   "text/x-setext"
            "exe"   "application/octet-stream"
            "gif"   "image/gif"
            "htm"   "text/html"
            "html"  "text/html"
            "ico"   "application/icon"
            "ics"   "text/calendar"
            "jpe"   "image/jpeg"
            "jpeg"  "image/jpeg"
            "jpg"   "image/jpeg"
            "js"    "text/javascript"
            "lha"   "application/octet-stream"
            "lzh"   "application/octet-stream"
            "mobileconfig"   "application/x-apple-aspen-config"
            "mov"   "video/quicktime"
            "mp4" "video/mp4"
            "mpe"   "video/mpeg"
            "mpeg"  "video/mpeg"
            "mpg"   "video/mpeg"
            "m3u8"  "application/x-mpegURL"
            "pbm"   "image/x-portable-bitmap"
            "pdf"   "application/pdf"
            "pgm"   "image/x-portable-graymap"
            "png"   "image/png"
            "pnm"   "image/x-portable-anymap"
            "ppm"   "image/x-portable-pixmap"
            "ppt"   "application/vnd.ms-powerpoint"
            "ps"    "application/postscript"
            "qt"    "video/quicktime"
            "ras"   "image/x-cmu-raster"
            "rb"    "text/plain"
            "rd"    "text/plain"
            "rtf"   "application/rtf"
            "sgm"   "text/sgml"
            "sgml"  "text/sgml"
            "so"    "application/octet-stream"
            "tif"   "image/tiff"
            "tiff"  "image/tiff"
            "ts"    "video/MP2T"
            "txt"   "text/plain"
            "xbm"   "image/x-xbitmap"
            "xls"   "application/vnd.ms-excel"
            "xml"   "text/xml"
            "xpm"   "image/x-xpixmap"
            "xwd"   "image/x-xwindowdump"
            "zip"   "application/zip"))
