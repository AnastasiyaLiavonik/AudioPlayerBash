#!/bin/bash

DIR=""
STRING=""
CHOOSE=0

creating_playlist()
{	
	find $DIR | grep "\.mp3" | sed "s#.*/##" > $PWD/.tmp.txt
	declare -a ARRAY
	while IFS= read -r line; do 
		ARRAY+=(FALSE "$line");
	done < $PWD/.tmp.txt
	ANS=$(zenity  --list --checklist --width=600 --height=450 --column="choose" --column="songs" "${ARRAY[@]}")
	echo "$ANS" > $PWD/.tmp.txt
	COUNT=0
	while read -n 1 CHAR ; do
	    	if [ "$CHAR" == '|' ]
		then
			COUNT=$((COUNT+1))
		fi
	done <<< "$ANS"
	> $PWD/.currentPlayList.txt
	while [ $COUNT != 0 ]; do
		cut -d "|" $PWD/.tmp.txt -f 1 >> $PWD/.currentPlayList.txt
		sed -i "s/^[^|]*//" $PWD/.tmp.txt
		sed -i "s/^|*//" $PWD/.tmp.txt
		COUNT=$((COUNT-1))	
	done
	cat $PWD/.tmp.txt >> $PWD/.currentPlayList.txt
	rm $PWD/.tmp.txt
}

killPausedProcess()
{
	if [[ "$PAUSE" == "true" ]]; then
	  	kill -9 $processNum 2>/dev/null
	fi
        PAUSE="false"
}

listening()
{
	if [[ -z $(grep '[^[:space:]]' $PWD/.currentPlayList.txt) ]]; then # jezeli pusty, nic nie wybralam	
		echo "You didn't choose any song to play" >> $HOME/Templates/.currentPlayList.txt
		cat $HOME/Templates/.currentPlayList.txt | zenity --text-info --title "___" --height 150 --width 150
		rm $HOME/Templates/.currentPlayList.txt
		return
	fi
	LINE=1
	PAUSE="false"
	ISSONGCHANGED="true"
	while [ 0 ]; do
	
		if [[ "$PAUSE" == "false" ]] || [[ "$ISSONGCHANGED" == "true" ]]; then
			SONG=$(head -n $LINE $PWD/.currentPlayList.txt | tail -n +$LINE)
			ARTIST=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			TITLE=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			GENRE=$(ffprobe -loglevel error -show_entries format_tags=genre -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			DATE=$(ffprobe -loglevel error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $DIR$SONG)
			echo "Title: $TITLE" > $PWD/.song.txt
			echo "Artist: $ARTIST" >> $PWD/.song.txt
			echo "Genre: $GENRE" >> $PWD/.song.txt
			echo "Date: $DATE" >> $PWD/.song.txt
			if [[ "$ISSONGCHANGED" == "true" ]]; then
				( mpg123 -q $DIR$SONG ) &
			fi
			PAUSE="false"
		fi
 	  	ANS=$(cat $PWD/.song.txt | zenity --text-info --title "Current Song" --extra-button "⏮" --extra-button ⏹️ --extra-button "⏸️" --extra-button "⏭" --height 200 --width 150 2>/dev/null)
	  	
	  	LASTLINE=$(wc -l < $PWD/.currentPlayList.txt)
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
  	rm $PWD/.currentPlayList.txt 
  	rm $PWD/.song.txt
}

selecting()
{		
	creating_playlist
	listening
}

random() 
{
	find $DIR | grep "\.mp3" | sed "s#.*/##" > $PWD/.songs.txt
	sort -R $PWD/.songs.txt > $PWD/.currentPlayList.txt
	listening
	rm $PWD/.songs.txt
}

lastModified()
{
	ls $DIR -Art | tail -n 10 > $PWD/.currentPlayList.txt
	listening
}


rename() 
{
	find $DIR | grep "\.mp3" | sed "s#.*/##" > $PWD/.songs.txt
	declare -a ARRAY
	while IFS= read -r LINE; do 
		ARRAY+=("$LINE"); 
	done < $PWD/.songs.txt
	CHANGED=0
	> $PWD/.renamedsongs.txt
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
			echo "$SONG -> $NEWNAME" >> $PWD/.renamedsongs.txt
			mv $DIR$SONG $DIR$NEWNAME
			CHANGED=$((CHANGED+1))
		fi
	done
	echo "Title changed for $CHANGED songs." >> $PWD/.renamedsongs.txt
	cat $PWD/.renamedsongs.txt | zenity --text-info --title "Count of changed titles" --height 400 --width 200
	rm $PWD/.songs.txt 
	rm $PWD/.renamedsongs.txt
}

DIR="$HOME/MUSIC/"
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

