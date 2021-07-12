#!/bin/bash

DIR=""
STRING=""
CHOOSE=0
FALSE="false"
TRUE="true"

creating_playlist()
{	
	find $DIR | grep "\.mp3" | sed "s#.*/##" > tmp
	declare -a ARRAY
	while IFS= read -r line; do 
		ARRAY+=(FALSE "$line");
	done < tmp
	ANS=$(zenity  --list --checklist --width=600 --height=450 --column="choose" --column="songs" "${ARRAY[@]}")
	echo "$ANS" > tmp
	COUNT=0
	while read -n 1 CHAR ; do
	    	if [ "$CHAR" == '|' ]
		then
			COUNT=$((COUNT+1))
		fi
	done <<< "$ANS"
	CURRENTPLAYLIST="/usr/local/bin/currentPlayList.txt"
	touch $CURRENTPLAYLIST
	while [ $COUNT != 0 ]; do
		cut -d "|" tmp -f 1 >> $CURRENTPLAYLIST
		sed -i "s/^[^|]*//" tmp
		sed -i "s/^|*//" tmp
		COUNT=$((COUNT-1))	
	done
	cat tmp >> $CURRENTPLAYLIST
	rm tmp
}

killPausedProcess()
{
	if [[ "$PAUSE" == $TRUE ]]; then
	  	kill -9 $processNum
	fi
        PAUSE=$FALSE
}

listening()
{
	if [[ -z $(grep '[^[:space:]]' $CURRENTPLAYLIST) ]]; then # jezeli pusty, nic nie wybralam	
		echo "You didn't choose any song to play" >> $CURRENTPLAYLIST
		cat $CURRENTPLAYLIST | zenity --text-info --title "___" --height 150 --width 150
		rm $CURRENTPLAYLIST
		return
	fi
	LINE=1
	PAUSE=$FALSE
	ISSONGCHANGED=$TRUE
	while [ 0 ]; do
	
		if [[ "$PAUSE" == $FALSE ]] || [[ "$ISSONGCHANGED" == $TRUE ]]; then
			SONG=$(head -n $LINE $CURRENTPLAYLIST | tail -n +$LINE)
			ARTIST=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			TITLE=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			GENRE=$(ffprobe -loglevel error -show_entries format_tags=genre -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			DATE=$(ffprobe -loglevel error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			PLAYINGSONG="/usr/local/bin/song.txt"
			echo "Title: $TITLE" > $PLAYINGSONG
			echo "Artist: $ARTIST" >> $PLAYINGSONG
			echo "Genre: $GENRE" >> $PLAYINGSONG
			echo "Date: $DATE" >> $PLAYINGSONG
			if [[ "$ISSONGCHANGED" == $TRUE ]]; then
				( mpg123 -q $DIR$SONG ) &
			fi
			PAUSE=$FALSE
		fi
		ANS=$(cat $PLAYINGSONG | zenity --text-info --title "Current Song" --extra-button "⏮" --extra-button ⏹️ --extra-button "⏸️" --extra-button "⏭" --height 200 --width 120 2>/dev/null)
	  	
	  	LASTLINE=$(wc -l < $CURRENTPLAYLIST)
	  	case "$ANS" in
	  		"⏸️")
        			processNum=$(ps -ef | grep mpg123 | head -n 1 | tr -s ' ' | cut -d ' ' -f2)
        			if [[ "$PAUSE" == $TRUE ]]; then
        				kill -CONT $processNum
        				PAUSE=$FALSE
        			else 
        				kill -STOP $processNum
        				PAUSE=$TRUE
        			fi
        			ISSONGCHANGED=$FALSE
        			continue;;
	  	esac
	  	ISSONGCHANGED=$TRUE
	  	case "$ANS" in
	  		"⏭") 
	  			killall mpg123
	  			if [[ "$LINE" = "$LASTLINE" ]]; then
					LINE=1
				else 
	  				LINE=$((LINE+1)) 
	  			fi
	  			killPausedProcess
	  			continue;;
	  		"⏮") 
	  			killall mpg123
	  			if [[ "$LINE" = "1" ]]; then 
					LINE="$LASTLINE"
				else
	        			LINE=$((LINE-1)) 
	        		fi
	        		killPausedProcess
	        		continue;;
        		"⏹️") 
        			killall mpg123 
        			killPausedProcess
        			continue;;
        	esac
	  	if [[ "$ANS" != 0 ]]; then
        		break
  		fi
  		LINE=$((LINE+1)) 
  	done
  	killall mpg123
  	rm $CURRENTPLAYLIST
  	rm $PLAYINGSONG
}

selecting()
{		
	creating_playlist
        COUNT=0
	listening
}

random() 
{
        COUNT=0
	CURRENTPLAYLIST="/usr/local/bin/currentPlaylist.txt"
	find $DIR | grep "\.mp3" | sed "s#.*/##" | sort -R > $CURRENTPLAYLIST 
	listening
}

lastModified()
{	
	CURRENTPLAYLIST="/usr/local/bin/currentPlaylist.txt"
	ls $DIR -Art | tail -n 10 > $CURRENTPLAYLIST
	listening
}


rename() 
{
	find $DIR | grep "\.mp3" | sed "s#.*/##" > tmp.txt
	declare -a ARRAY
	while IFS= read -r LINE; do 
		ARRAY+=("$LINE"); 
	done < tmp.txt
	rm tmp.txt
	CHANGED=0
	RENAMEDSONGS="/usr/local/bin/renamedSongs.txt"
	> $RENAMEDSONGS
	for SONG in "${ARRAY[@]}"
	do
		ARTIST=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
		TITLE=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
		NEWNAME=""
		if [[ $ARTIST ]]; then
			NEWNAME+="$ARTIST"
			if [[ $TITLE ]]; then 	
				NEWNAME+="-"
				NEWNAME+="$TITLE"
			fi
		else
			NEWNAME+="$TITLE"
		fi
		NEWNAME=$(echo $NEWNAME | sed 's/bpm//g' | tr -d '0123456789' | sed 's/ \{1,\}/ /g' | tr -d ' ')
		NEWNAME+=".mp3"
		echo
		if [[ "$SONG" != "$NEWNAME" ]]; then
			echo "$SONG -> $NEWNAME" >> $RENAMEDSONGS
			mv $DIR$SONG $DIR$NEWNAME
			CHANGED=$((CHANGED+1))
		fi
	done
	echo "Title changed for $CHANGED songs." >> $RENAMEDSONGS
	cat $RENAMEDSONGS | zenity --text-info --title "Count of changed titles" --height 400 --width 300
	rm $RENAMEDSONGS
}

DIR="/home/"$(id -un)"/"
FILESCRIPTNAME=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
ME=$(stat -c '%U' $FILESCRIPTNAME)
EMAIL=""
LASTMODIFIED=$( date -r $FILESCRIPTNAME )
HEADERFILE="/usr/local/bin/header.txt"
echo "# Author           : $ME ( $EMAIL )" > $HEADERFILE
echo "# Created On       : " >> $HEADERFILE
echo "# Last Modified By : $ME ( $EMAIL )" >> $HEADERFILE
echo "# Last Modified On : $LASTMODIFIED" >> $HEADERFILE
echo "# Version          : 1" >> $HEADERFILE
echo "#" >> $HEADERFILE
echo "# Description      : Skrypt pozwala na sluchanie muzyki. Sa roznego rodzaju opcje: mozna posluchac wybranej przez siebie muzyki, mozna randomowo przydzielic playback, rowniez mozna posluchac ostatnio dodanej muzyki. Istnieje tez mozliwosc zmiany nazw piosenek w sposob prawidlowy." >> $HEADERFILE
echo "#" >> $HEADERFILE
echo "# Licensed under GPL (see /usr/share/common-licenses/GPL for more details">> $HEADERFILE
echo "# or contact # the Free Software Foundation for a copy)" >> $HEADERFILE

while getopts hv OPT; do
	case $OPT in
		h) echo "Option help";;
		v) echo "Option version";;
		*) echo "Undefined option";;
	esac
done

cat $HEADERFILE | zenity --title "_____" --text-info --height 350 --width 550
rm $HEADERFILE
MUSICFILE=$(zenity --entry --title "Path request" --text "Please enter the path to the file with music")
DIR="${DIR}$MUSICFILE"

while [ "$CHOOSE" != 5 ]; do

		CHOOSE1="1. Select music "
		CHOOSE2="2. Random music playback "
		CHOOSE3="3. Listen recently added "
		CHOOSE4="4. Rename filenames properly "
		CHOOSE5="5. End"

	MENU=("$CHOOSE1" "$CHOOSE2" "$CHOOSE3" "$CHOOSE4" "$CHOOSE5")
	CHOOSE=$(zenity --list --column="What do you want to do?" "${MENU[@]}" --height 300 --width 350)

	case "$CHOOSE" in

		$CHOOSE1) selecting;;
		$CHOOSE2) random;;
		$CHOOSE3) lastModified;;
		$CHOOSE4) rename;;
		$CHOOSE5) CHOOSE=5;;
	
	esac

done
