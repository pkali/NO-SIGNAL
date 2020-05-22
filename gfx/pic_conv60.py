import Image
import time
import pirxompr

#---------------------------------------------------
#--------------main---------------------------------
#---------------------------------------------------


#path="C:/My Dropbox/folder_roboczy_atari/projects/intro_glucholazy/gfx/png/"
path = ""

start = time.time()

screen = []
charScreenLines = []
for i in range(1,17):
    imageFile = "frame"+str("%02d" % i)+".png"
    im = Image.open(path+imageFile)
    print imageFile
    screen.append(pirxompr.png2gr9and10(im))


miker =[]
pirx = []
sikor = []


for j in range(0,10):
    print "Result line nr",j
    charScreenLines = []
    for i in range (0,16):
        charScreenLines = charScreenLines + pirxompr.getLines(screen[i],j,j+1)
    mapTable = pirxompr.optimiseCharScreen(charScreenLines,128,0.5)
    pirxompr.charScreenBinWriter("charset"+str("%02d" % j)+".fnt",charScreenLines)
    pirxompr.intListBinWriter("mapa"+str("%02d" % j)+".bin",mapTable)
    for frame in range(0,16):
        miker = miker + mapTable[3+40*frame:(10+1)+40*frame]
        pirx = pirx + mapTable[14+40*frame:(23+1)+40*frame]
        sikor = sikor + mapTable[30+40*frame:(38+1)+40*frame]

pirxompr.intListBinWriter("miker.bin",miker)
pirxompr.intListBinWriter("pirx.bin",pirx)
pirxompr.intListBinWriter("sikor.bin",sikor)
    
end = time.time()
print "Total time:",end - start
