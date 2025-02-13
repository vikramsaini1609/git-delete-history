#!/bin/bash
#set -x

# Shows you the largest objects in your repo's pack file.
# Written for osx.
#
# @see http://stubbisms.wordpress.com/2009/07/10/git-script-to-show-largest-pack-objects-and-trim-your-waist-line/
# @author Antony Stubbs

# set the internal field spereator to line break, so that we can iterate easily over the verify-pack output
IFS=$'\n';

printf "\nDo you want to delete files from git history... [y/n]?(n)"
read -r wantToDeleteFiles

# list all objects including their size, sort by size, take top 10
objects=`git verify-pack -v .git/objects/pack/pack-*.idx | grep -Ev "non delta|chain length|git/objects" | tr -s " " | sort -k3gr | head -n2000`

echo "All sizes are in kB's."
printf "Size(KB's),File,Is file exist\n" >> git-large-files-4.csv

output="size,SHA,location"
for y in $objects
do
  # extract the size in KB
  #1024 = 1MB
  size=$((`echo $y | cut -f 3 -d ' '`"/1024"))
  if [ "$size" -ge "1024" ];
  then
     path='D:\Project\Git-delete-history\'
     # extract the SHA
      sha=`echo $y | cut -f 1 -d ' '`
      # find the objects location in the repository tree
      other=`git rev-list --all --objects | grep $sha`
      #lineBreak=`echo -e "\n"`
      IFS=' ' read -ra objects_output <<< "$other"

      file_exist="No"
      # Checking file is still exist current working tree.
      if [ -e "${path}${objects_output[1]}" ];
      then
          file_exist="Yes"
      else
        if [ "$wantToDeleteFiles" == "y" ];
        then
          echo "deleting file: ${objects_output[1]} \n"
          git filter-repo --force --path "${objects_output[1]}" --invert-paths
        fi
      fi
      #Create CSV if don't want to delete the files
      if [ "$wantToDeleteFiles" != "y" ];
      then
        output="${output}\n${size},${other},${file_exist}"
        #Creating CSV file
        printf "${size},${objects_output[1]},${file_exist}\n" >> git-large-files.csv
      fi
  fi

done

if [ "$wantToDeleteFiles" != "y" ];
then
  echo -e $output | column -t -s ', '
fi
