#!/bin/bash

DIR=""
STRING=""
CHOOSE=0

creating_playlist()
{	
	find $DIR | grep "\.mp3" | sed "s#.*/##" > tmp
	declare -a ARRAY
	while IFS= read -r line; do 
		ARRAY+=(FALSE "$line");
	done < tmp
	ANS=$(zenity  --list --checklist --width=600 --height=450 --column="choose" --column="songs" "${ARRAY[@]}")
	echo "$ANS" > tmp1
	COUNT=0
	while read -n 1 CHAR ; do
	    	if [ "$CHAR" == '|' ]
		then
			COUNT=$((COUNT+1))
		fi
	done <<< "$ANS"
	> currentPlayList.txt
	while [ $COUNT != 0 ]; do
		cut -d "|" tmp1 -f 1 >> currentPlayList.txt
		sed -i "s/^[^|]*//" tmp1 
		sed -i "s/^|*//" tmp1
		COUNT=$((COUNT-1))	
	done
	cat tmp1 >> currentPlayList.txt
	rm tmp
	rm tmp1
}

killPausedProcess()
{
	if [[ "$PAUSE" == "true" ]]; then
	  	kill -9 $processNum
	fi
        PAUSE="false"
}

listening()
{
	if [[ -z $(grep '[^[:space:]]' currentPlayList.txt) ]]; then # jezeli pusty, nic nie wybralam	
		echo "You didn't choose any song to play" >> currentPlayList.txt
		cat currentPlayList.txt | zenity --text-info --title "___" --height 150 --width 150
		rm currentPlayList
		return
	fi
	LINE=1
	PAUSE="false"
	ISSONGCHANGED="true"
	while [ 0 ]; do
	
		if [[ "$PAUSE" == "false" ]] || [[ "$ISSONGCHANGED" == "true" ]]; then
			SONG=$(head -n $LINE currentPlayList.txt | tail -n +$LINE)
			ARTIST=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			TITLE=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			GENRE=$(ffprobe -loglevel error -show_entries format_tags=genre -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			DATE=$(ffprobe -loglevel error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			echo "Title: $TITLE" > song.txt
			echo "Artist: $ARTIST" >> song.txt
			echo "Genre: $GENRE" >> song.txt
			echo "Date: $DATE" >> song.txt
			if [[ "$ISSONGCHANGED" == "true" ]]; then
				( mpg123 -q $DIR$SONG ) &
			fi
			PAUSE="false"
		fi
 	  	ANS=$(cat song.txt | zenity --text-info --title "Current Song" --extra-button "⏮" --extra-button ⏹️ --extra-button "⏸️" --extra-button "⏭" --height 200 --width 150 2>/dev/null)
	  	
	  	LASTLINE=$(wc -l < currentPlayList.txt)
	  	case "$ANS" in
	  		"⏸️")
        			processNum=$(ps -ef | grep mpg123 | head -n 1 | tr -s ' ' | cut -d ' ' -f2)
        			if [[ "$PAUSE" == "true" ]]; then
        				kill -CONT $processNum
        				PAUSE="false"
        			else 
        				kill -STOP $processNum
        				PAUSE="true"
        			fi
        			ISSONGCHANGED="false"
        			continue;;
	  	esac
	  	ISSONGCHANGED="true"
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
  	rm currentPlayList.txt 
  	rm song.txt
}

selecting()
{		
	creating_playlist
	listening
}

random() 
{
	find $DIR | grep "\.mp3" | sed "s#.*/##" > songs.txt
	sort -R songs.txt > currentPlayList.txt
	listening
	rm songs.txt
}

lastModified()
{
	ls $DIR -Art | tail -n 10 > currentPlayList.txt
	listening
}


rename() 
{
	find $DIR | grep "\.mp3" | sed "s#.*/##" > songs.txt
	declare -a ARRAY
	while IFS= read -r LINE; do 
		ARRAY+=("$LINE"); 
	done < songs.txt
	CHANGED=0
	> renamedsongs.txt
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
			echo "$SONG -> $NEWNAME" >> renamedsongs.txt
			mv $DIR$SONG $DIR$NEWNAME
			CHANGED=$((CHANGED+1))
		fi
	done
	echo "Title changed for $CHANGED songs." >> renamedsongs.txt
	cat renamedsongs.txt | zenity --text-info --title "Count of changed titles" --height 400 --width 200
	rm songs.txt 
	rm renamedsongs.txt
}

DIR="/home/"$(id -un)"/MUSIC/"
NAME=$(zenity --entry --title "_____" --text "Hello! Welcome to my new app! What is your name?" --height 350 --width 400)

while [ "$CHOOSE" != 5 ]; do
		CHOOSE1="1. Select music "
		CHOOSE2="2. Random music playback "
		CHOOSE3="3. Listen recently added "
		CHOOSE4="4. Rename filenames properly "
		CHOOSE5="5. End"

	MENU=("$CHOOSE1" "$CHOOSE2" "$CHOOSE3" "$CHOOSE4" "$CHOOSE5")
	CHOOSE=$(zenity --list --column="What do you want to do, $NAME?" "${MENU[@]}" --height 400 --width 350)

	case "$CHOOSE" in

		$CHOOSE1) selecting;;
		$CHOOSE2) random;;
		$CHOOSE3) lastModified;;
		$CHOOSE4) rename;;
		$CHOOSE5) CHOOSE=5;;
	
	esac

done
