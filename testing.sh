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
	rm tmp
	rm tmp1
}

listening()
{
	line=1
	if [[ -z $(grep '[^[:space:]]' currentPlayList.txt) ]] # jezeli pusty, nic nie wybralam
	then	
		echo "You didn't choose any song to play" >> currentPlayList.txt
		cat currentPlayList.txt | zenity --text-info --title "___" --height 150 --width 150
		rm currentPlayList
		return
	fi
	while [ 0 ]; do
		
		song=$(head -n $line currentPlayList.txt | tail -n +$line)
		artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		genre=$(ffprobe -loglevel error -show_entries format_tags=genre -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		date=$(ffprobe -loglevel error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		echo "Title: $title" > song.txt
		echo "Artist: $artist" >> song.txt
		echo "Genre: $genre" >> song.txt
		echo "Date: $date" >> song.txt
		
		( mpg123 $DIR$song ) &
 	  	ans=$(cat song.txt | zenity --text-info --title "Current Song" --extra-button "⏮" --extra-button ⏹️ --extra-button "⏭" --height 200 --width 150)
	  	
	  	last_line=$(wc -l < currentPlayList.txt)
	  	killall mpg123
	  	case "$ans" in
	  		"⏭") 
	  			if [[ "$line" = "$last_line" ]]
				then
					line=1
				else 
	  				line=$((line+1)) 
	  			fi
	  			continue;;
	  		"⏮") 
	  			if [[ "$line" = "1" ]]
				then 
					line="$last_line"
				else
	        			line=$((line-1)) 
	        		fi
        			continue;;
        		"⏹️")
        			continue;;
	  	esac	
	  	if [[ "$ans" != 0 ]]
        	then
        		break
  		fi
  		line=$((line+1)) 
  		echo "$line"
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
	declare -a array
	while IFS= read -r line; do 
		array+=("$line"); 
	done < songs.txt
	changed=0
	> renamedsongs.txt
	for song in "${array[@]}"
	do
		artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 $DIR$song)
		newName=""
		if [[ $artist ]]
		then
			newName+="$artist"
			if [[ $title ]]
			then 	
				newName+="-"
				newName+="$title"
			fi
		else
			newName+="$title"
		fi
		newName=$(echo $newName | sed 's/bpm//g' | tr -d '0123456789' | sed 's/ \{1,\}/ /g' | tr -d ' ')
		newName+=".mp3"
		echo
		if [[ "$song" != "$newName" ]]
		then
			echo "$song -> $newName" >> renamedsongs.txt
			mv $DIR$song $DIR$newName
			changed=$((changed+1))
		fi
	done
	echo "Title changed for $changed songs." >> renamedsongs.txt
	cat renamedsongs.txt | zenity --text-info --title "Count of changed titles" --height 400 --width 200
	rm songs.txt 
	rm renamedsongs.txt
}

DIR="/home/"$(id -un)"/MUSIC/"
NAME=$(zenity --entry --title "_____" --text "Hello! Welcome to my new app! What is your name?" --height 350 --width 400)

while [ "$choose" != 5 ]; do
		choose1="1. Select music "
		choose2="2. Random music playback "
		choose3="3. Listen recently added "
		choose4="4. Rename filenames properly "
		choose5="5. End"

	MENU=("$choose1" "$choose2" "$choose3" "$choose4" "$choose5")
	choose=$(zenity --list --column="What do you want to do, $NAME?" "${MENU[@]}" --height 400 --width 350)

	case "$choose" in

		$choose1) selecting;;
		$choose2) random;;
		$choose3) lastModified;;
		$choose4) rename;;
		$choose5) choose=5;;
	
	esac

done
