import Image
import time
import pirxompr

#---------------------------------------------------
#--------------main---------------------------------
#---------------------------------------------------



#path="C:/My Dropbox/folder_roboczy_atari/projects/intro_glucholazy/gfx/png/"
path =""

start = time.time()

charScreenLines = []
i=1
imageFile = "frame"+str("%02d" % i)+".png"
im = Image.open(path+imageFile)
print imageFile

screen=pirxompr.png2gr9and10(im)
charScreenLines = charScreenLines + pirxompr.getLines(screen,10,20)

mapTable = pirxompr.optimiseCharScreen(charScreenLines)
pirxompr.charScreenBinWriter("charset_bottom.fnt",charScreenLines)
pirxompr.intListBinWriter("mapa_bottom.bin",mapTable)

    
end = time.time()
print end - start
