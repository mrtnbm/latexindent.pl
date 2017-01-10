#!/bin/bash

# A little script to help me run through test cases

#echo latexindent.pl -w -l=table5.yaml -s table5
#latexindent.pl -w -l=table5.yaml -s table5

silentMode=0
silentModeFlag=''
showCounterFlag=''
noisyModeFlag=''
# check flags, and change defaults appropriately
while getopts "sco:n" OPTION
do
 case $OPTION in 
  s)    
   echo "Silent mode on..."
   silentModeFlag='-s'
   silentMode=1
   ;;
  c)    
   echo "Show counter mode active!"
   showCounterFlag='-c'
   ;;
  o)
    # only do this one in the loop
    loopminFlag="-o $OPTARG"
   ;;
  n)
    # only do this one in the loop
    noisyModeFlag="-n"
    noisyMode=1
   ;;
  ?)    printf "Usage: %s: [-s]  args\n" $(basename $0) >&2
        exit 2
        ;;
 # end case
 esac 
done

# set verbose mode, 
# see http://stackoverflow.com/questions/2853803/in-a-shell-script-echo-shell-commands-as-they-are-executed

# environment objects
cd environments
[[ $silentMode == 1 ]] && echo "./environments/environments-test-cases.sh"
./environments-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# ifelsefi objects
cd ../ifelsefi
[[ $silentMode == 1 ]] && echo "./ifelsefi/ifelsefi-test-cases.sh"
./ifelsefi-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# optional arguments in environments
cd ../opt-args
[[ $silentMode == 1 ]] && echo "./opt-args/opt-args-test-cases.sh"
./opt-args-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# mandatory arguments in environments
cd ../mand-args
[[ $silentMode == 1 ]] && echo "./mand-args/mand-args-test-cases.sh"
./mand-args-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# mixture of optional and mandatory arguments
cd ../opt-and-mand-args/
[[ $silentMode == 1 ]] && echo "./opt-and-mand-args/opt-and-mand-args-test-cases.sh"
./opt-mand-args-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# items
cd ../items/
[[ $silentMode == 1 ]] && echo "./items/items-test-cases.sh"
./items-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# commands
cd ../commands/
[[ $silentMode == 1 ]] && echo "./commands/commands-test-cases.sh"
./commands-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# key equals value braces
cd ../keyEqualsValueBraces/
[[ $silentMode == 1 ]] && echo "./keyEqualsValueBraces/key-equals-values-test-cases.sh"
./key-equals-values-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# file extension
cd ../fileextensions/
[[ $silentMode == 1 ]] && echo "./fileextensions/file-extension-test-cases.sh"
./file-extension-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# token checks
cd ../tokenChecks/
[[ $silentMode == 1 ]] && echo "./tokenChecks/token-checks.sh"
./token-checks.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# cruft directory
cd ../cruftdirectory/
[[ $silentMode == 1 ]] && echo "./cruftdirectory/cruft-directory-test-cases.sh"
./cruft-directory-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# named grouping braces
cd ../namedGroupingBracesBrackets
[[ $silentMode == 1 ]] && echo "./namedGroupingBracesBrackets/named-grouping-test-cases.sh"
./named-grouping-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# specials
cd ../specials
[[ $silentMode == 1 ]] && echo "./specials/specials-test-cases.sh"
./specials-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# headings
cd ../headings
[[ $silentMode == 1 ]] && echo "./headings/headings-test-cases.sh"
./headings-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# filecontents
cd ../filecontents
[[ $silentMode == 1 ]] && echo "./filecontents/filecontents-test-cases.sh"
./filecontents-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# alignment
cd ../alignment
[[ $silentMode == 1 ]] && echo "./alignment/alignment-test-cases.sh"
./alignment-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# texexchange
cd ../texexchange
[[ $silentMode == 1 ]] && echo "./texexchange/texexchange-test-cases.sh"
./texexchange-test-cases.sh $silentModeFlag $showCounterFlag $loopminFlag $noisyModeFlag
# play sounds
for i in {1..5}
do 
  [[ $noisyMode == 1 ]] && paplay /usr/share/sounds/freedesktop/stereo/complete.oga
done
exit
