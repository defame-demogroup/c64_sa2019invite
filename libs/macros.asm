



.macro _toBytes( items ) {
	.for (var i = 0 ; i < items.size() ; i++) {
		.byte items.get(i)
	}
}


.macro _outputMusicInfo(music){
    //----------------------------------------------------------
// Print the music info while assembling
.print ""
.print "SID Data"
.print "--------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright
.print ""
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
}

.macro _injectMusicData(music){
    .pc=music.location "Music"
    .fill music.size, music.getData(i)
}
 