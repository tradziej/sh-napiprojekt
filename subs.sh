#!/bin/bash
[[ -z "$@" ]] && { echo "No files selected" 1>&2; exit 1; }

lang=$(echo "$1"|tr '[:lower:]' '[:upper:]'); shift
[[ "$lang" != "PL" && "$lang" != "EN" ]] && { echo "Wrong language $lang" 1>&2; exit 1; }
for file in "$@"; do
	echo "Processing $file..."

	[ -f "$file" ] || { echo "Error reading file" 1>&2; exit 1; }
	md5=`head "$file" -c 10485760|md5sum -b -|cut -f 1 -d ' '`
	add=(0 13 16 11 5)
	mul=(2 2 5 4 3)
	idx=(14 3 6 8 2)
	checksum=''
	for i in {0..4}; do
		a=${add[@]:$i:1}
		m=${mul[@]:$i:1}
		x=${idx[@]:$i:1}
		t=$(( $a + $((0x${md5:$x:1})) ))
		v=$((0x${md5:$t:2}))
		checksum+=$(printf '%x' $(( $v * $m )) | tail -c 1 )
	done

	url="http://napiprojekt.pl/unit_napisy/dl.php?l=$lang&f=$md5&t=$checksum&v=other&kolejka=false&nick=&pass=&napios=posix"
	tmpfile="$(mktemp)"
	wget "$url" -qO "$tmpfile"

	if [[ "$(head "$tmpfile" -c 3)" == "NPc" ]]; then
		echo "Subtitles not found." 1>&2
	else
		outfile="${file%.*}.sub"
		napipass="iBlm8NTigvru0Jr0"
		#assert it unpacks just one file named in $md5.* fashion
		/usr/bin/7z x -y -p"$napipass" "$tmpfile" >/dev/null 2>/dev/null && cp "$md5".* "$outfile"
		[[ $? -eq 0 ]] && echo "Subtitles stored OK." || echo "Error extracting." 1>&2
		rm "$md5".*
	fi

	rm "$tmpfile"
done
