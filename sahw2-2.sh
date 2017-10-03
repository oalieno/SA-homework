#! /usr/bin/sh
exec 2> ~/.mybrowser/error.log

INPUT="/tmp/input"
LINKS="/tmp/links"
HISTORY="/tmp/myhistory"
BOOKMARKS=".mybrowser/bookmark"

TITLE="My Browser"
CURRENT=""
URL="https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)"
SKIP=0
NOW=0
TRAVEL=0

>$INPUT
>$LINKS
>$HISTORY

TERMS () {
    dialog --title "Terms and Conditions of Use" --yesno "$(cat .mybrowser/userterm)" 200 100
}

BYE () {
    dialog --title "Bye!" --msgbox "You break my heart..." 200 100
}

BROWSE () {
    dialog --title "$TITLE" --msgbox "$(w3m -dump $CURRENT)" 200 100
}

BROWSE_SOURCE () {
    dialog --title "$TITLE" --msgbox "$(w3m -dump_source $CURRENT)" 200 100
}

GET_LINKS () {
    w3m -dump_source $CURRENT | sed -rn 's:.*<a href="(.*)".*:\1:p' | awk -v current="$CURRENT" 'BEGIN{ORS=""}!/http[s]:/{print current}{print $0 "\n"}' >$LINKS
}

LINKS () {
    dialog --title "$TITLE" --menu "$1" 200 100 $(cat $LINKS | wc -l | sed 's:[^0-9]::g') $(cat $LINKS | awk 'BEGIN{ORS=" "}{print NR,$0}') 2>$INPUT
    if [ $? == 0 ]; then
        cat $LINKS | awk -v chose=$(cat $INPUT) 'NR == chose' >$INPUT
	SKIP=1
    fi
}

DOWNLOAD () {
    dialog --title "$TITLE" --menu "$1" 200 100 $(cat $LINKS | wc -l | sed 's:[^0-9]::g') $(cat $LINKS | awk 'BEGIN{ORS=" "}{print NR,$0}') 2>$INPUT
    if [ $? == 0 ]; then
        cat $LINKS | awk -v chose=$(cat $INPUT) 'NR == chose' >$INPUT
        wget --quiet -P Downloads/ $(cat $INPUT)
    fi
}

BOOKMARK () {
    dialog --title "$TITLE" --menu "Bookmarks:" 200 100 $(($(cat $BOOKMARKS | wc -l | sed 's:[^0-9]::g')+2)) $(cat $BOOKMARKS | awk 'BEGIN{ORS=" ";print "1 Add_a_bookmark 2 Delete_a_bookmark"}{print NR+2,$0}') 2>$INPUT
    if [ $? == 0 ]; then
        if [ $(cat $INPUT) == 1 ]; then
  	    dialog --title "$TITLE" --inputbox "Add:" 200 100 2>$INPUT
	    if [ $? == 0 ]; then
	        echo $(cat $INPUT)  >>$BOOKMARKS
    	    fi
        elif [ $(cat $INPUT) == 2 ]; then
            dialog --title "$TITLE" --menu "Delete:" 200 100 $(cat $BOOKMARKS | awk 'BEGIN{ORS=""}END{print NR}') $(cat $BOOKMARKS | awk 'BEGIN{ORS=" "}{print NR,$0}') 2>$INPUT
    	    if [ $? == 0 ]; then
	        cat $BOOKMARKS | awk -v chose=$(cat $INPUT) 'NR != chose' >$BOOKMARKS
   	    fi
        else
            cat $BOOKMARKS | awk -v chose=$(cat $INPUT) 'NR == chose-2' >$INPUT
	    SKIP=1
        fi
    fi
}

HELP () {
    dialog --title "$TITLE" --msgbox "$(cat .mybrowser/help)" 200 100
}

EXECUTE () {
    dialog --title "$TITLE" --msgbox "$($(cat $INPUT | sed 's:!::'))" 200 100
}

INVALID () {
    dialog --title "$TITLE" --msgbox "Invalid Input\nType /H for help" 200 100
}

TERMS

if [ $? != 0 ]; then
    BYE
    exit 0
fi

while true; do
    if [ $SKIP == 0 ]; then
        dialog --title "$TITLE" --inputbox "$CURRENT" 200 100 2>$INPUT
    fi
    if [ "$?" != "0" ]; then 
        break
    elif cat $INPUT | grep -Eq $URL; then
        CURRENT=$(cat $INPUT)
	if [ $TRAVEL == 0 -a "$(cat $HISTORY | awk 'END{print $0}')" != "$(cat $INPUT)" ]; then
	    if [ "$(cat $HISTORY)" != "" ]; then
	        echo "$(cat $HISTORY | awk -v now=$NOW 'NR <= now')" >$HISTORY
 	    fi
	    echo "$CURRENT" >>$HISTORY
	    NOW=$(cat $HISTORY | awk -v now=$NOW 'BEGIN{ORS=""}END{print NR}')
	fi
	TRAVEL=0
	SKIP=0
	BROWSE
	GET_LINKS
    elif cat $INPUT | grep -Eq "^(/S|/source)$"; then
	BROWSE_SOURCE
    elif cat $INPUT | grep -Eq "^(/L|/link)$"; then
	LINKS
    elif cat $INPUT | grep -Eq "^(/D|/download)$"; then
	DOWNLOAD
    elif cat $INPUT | grep -Eq "^(/B|/bookmark)$"; then
	BOOKMARK
    elif cat $INPUT | grep -Eq "^(/H|/help)$"; then
	HELP
    elif cat $INPUT | grep -Eq "^(/N|/next)$"; then
	echo "$(cat $HISTORY | awk -v now=$NOW 'NR == now+1')" >$INPUT
	if [ "$(cat $INPUT)" != "" ]; then
	    NOW=$(($NOW+1))
	    TRAVEL=1
	    SKIP=1
	fi
    elif cat $INPUT | grep -Eq "^(/P|/prev)$"; then
	echo "$(cat $HISTORY | awk -v now=$NOW 'NR == now-1')" >$INPUT
	if [ "$(cat $INPUT)" != "" ]; then
	    NOW=$(($NOW-1))
	    TRAVEL=1
	    SKIP=1
	fi
    elif cat $INPUT | grep -Eq "^\!"; then
	EXECUTE
    else 
	INVALID
    fi
done

rm $INPUT $LINKS $HISTORY
