
[1mFrom:[0m /home/muta/repos/kumi-play/web/app/services/kumi_compile.rb:34 KumiCompile.parse_error_location:

    [1;34m32[0m: [32mdef[0m [1;36mself[0m.[1;34mparse_error_location[0m(message)
    [1;34m33[0m: require [31m[1;31m"[0m[31mpry[1;31m"[0m[31m[0m
 => [1;34m34[0m: binding.pry
    [1;34m35[0m:   [32mif[0m message =~ [35m[1;35m/[0m[35mline=([1;35m\d[0m[35m+).[1;35m\s[0m[35m*column=([1;35m\d[0m[35m+)>[1;35m/[0m[35m[0m
    [1;34m36[0m:     line = [1;32m$1[0m.to_i
    [1;34m37[0m:     column = [1;32m$2[0m.to_i
    [1;34m38[0m: 
    [1;34m39[0m:     error_text = message.split([31m[1;31m"[0m[31m[1;35m\n[0m[31m[1;31m"[0m[31m[0m).last&.strip || message
    [1;34m40[0m: 
    [1;34m41[0m:     {
    [1;34m42[0m:       [35mmessage[0m: error_text,
    [1;34m43[0m:       [35mline[0m: line,
    [1;34m44[0m:       [35mcolumn[0m: column
    [1;34m45[0m:     }
    [1;34m46[0m:   [32melse[0m
    [1;34m47[0m:     { [35mmessage[0m: message }
    [1;34m48[0m:   [32mend[0m
    [1;34m49[0m: [32mend[0m

