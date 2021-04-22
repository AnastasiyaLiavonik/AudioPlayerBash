#!/bin/bash

DIR=""
STRING=""
choose=0

creating_playlist()
{	
	find $DIR | grep "\.mp3" | sed "s#.*/##" > tmp
	declare -a array
	while IFS= read -r line; do 
		array+=(FALSE "$line");
	done < tmp
	ans=$(zenity  --list --checklist --width=600 --height=450 --column="choose" --column="songs" "${array[@]}")
	echo "$ans" > tmp1
	count=0
	while read -n 1 char ; do
	    	if [ "$char" == '|' ]
		then
			count=$((count+1))
		fi
	done <<< "$ans"
	> currentPlayList.txt
	while [ $count != 0 ]
	do
		cut -d "|" tmp1 -f 1 >> currentPlayList.txt
		sed -i "s/^[^|]*//" tmp1 
		sed -i "s/^|*//" tmp1
		count=$((count-1))	
	done
	cat tmp1 >> currentPlayList.txt
	rm tmp1
}

listening()
{		
	creating_playlist
	
	rc=1 # OK button return code =0 , all others =1
	line=1
	if [[ -z $(grep '[^[:space:]]' currentPlayList.txt) ]] # jezeli pusty, nic nie wybralam
	then
		return
	fi
	while [ $rc -eq 1 ]; do
		
		song=$(head -n $line currentPlayList.txt | tail -n +$line)
		artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		genre=$(ffprobe -loglevel error -show_entries format_tags=genre -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		date=$(ffprobe -loglevel error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		echo "Title: $title" > song.txt
		echo "Artist: $artist" >> song.txt
		echo "Genre: $genre" >> song.txt
		echo "Date: $date" >> song.txt
		
	  	ans=$(cat song.txt | zenity --text-info "f" --title "Current Song" --cancel-label Quit --ok-label OK --extra-button "<" --extra-button PAUSE --extra-button ">"| mplayer $DIR$song)
		rc=$?
		echo "${rc}-${ans}"
	  	echo $ans
  		if [[ $ans = "<" ]]
	  	then
	  		echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        		line=$((line+1))
        	elif [[ $ans = ">" ]]
        	then
        		line=$((line+1))
  		fi
	done
	#mpg123 $line
}

DIR="/home/"$(id -un)"/MUSIC/"
NAME=$(zenity --entry --title "_____" --text "Hello! Welcome to my new app! What is your name?" --height 350 --width 400)

while [ "$choose" != 9 ]; do
		choose1="1. Listen music: "
		choose2="2. Catalog: $DIRECTORY "
		choose3="3. Check where you can find this file:"
		choose4="4. Content of file: "
		choose5="5. Does string exist in file: "
		choose6="6. Last modification time: " 
		choose7="7. Size of file/catolog: "
		choose8="8. Owner of file: "
		choose9="9. End" 

	MENU=("$choose1" "$choose2" "$choose3" "$choose4" "$choose5" "$choose6" "$choose7" "$choose8" "$choose9")
	choose=$(zenity --list --column="What do you want to do, $NAME?" "${MENU[@]}" --height 400 --width 350)

	case "$choose" in

		$choose1) listening;;
		$choose2) ;;
		$choose3) ;;
		$choose4) ;;
		$choose5) ;;
		$choose6) ;;
		$choose7) ;;
		$choose8) ;;
		$choose9) choose=9;;
	
	esac

done
