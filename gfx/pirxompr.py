import Image
from math import sqrt
import struct

def intListBinWriter(filename,intList):
    out = open(filename,"wb")
    for byte in intList:
        data=struct.pack('B', byte)
        out.write(data)
    out.close()
    return

def charScreenBinWriter(filename,charScreen):
    out = open(filename,"wb")
    for charLine in charScreen:
        for byte in charLine:
            data=struct.pack('B', byte)
            out.write(data)
    out.close()
    return
    

def charScreenPrinter(filename,charScreen):
    out = open(filename,"w")
    for charLine in charScreen:
        print >>out,"    .byte",
        for byte in range(0,len(charLine)-1):
            print >>out,charLine[byte],",",
        print >>out,charLine[len(charLine)-1]
    out.close()
    return

def intListPrinter(filename,intList):
    out = open(filename,"w")
    print >>out,"    .byte",
    for byte in range(0,len(intList)-1):
        print >>out,intList[byte],",",
    print >>out,intList[len(intList)-1]
    out.close()
    return
        
def img1bit2gr8(im):
    ''' converts image to gr.8
        height % 8 == 0 !!!
        width % 8 == 0 !!!
    '''
    sourceWidth = im.size[0]
    sourceHeight = im.size[1]
    screen = []
    for y in  range(0,sourceHeight):
        line = []
        for x in range(0,sourceWidth):
            pixel = im.getpixel((x,y)) & 1
            line.append( pixel )
        screen.append(line)
    #screen contains the data pixel by pixel 
    #screenOut has got pixels merged into bytes
        
    screenOut = []
    for line in screen:
        lineOut = []
        for i in range(0,sourceWidth/8):
            longpix = 0
            for j in range(0,8):
                longpix = longpix + 2**(7-j) * line[i*8+j]
            lineOut.append(longpix)
        screenOut.append(lineOut)
    return screenOut

def png2gr9and10(im):
    ''' converts image to gr.9 and gr.10 (with 1/2 pixel shift to the right)
        image MUST be 320 pixels wide
        height % 8 == 0 !
    '''

    screen = []
    
    #height = im.size[1]

    for y in  range(0,im.size[1]):
        line = []
        for x in range(0,80):
            bw_sum=0
            for k in range (0,4):
                if (y%2 == 0):
                    pixel = im.getpixel((x*4+k,y))
                else:
                    if x*4+k+2 < 320:
                        pixel = im.getpixel((x*4+k+2,y))
                    else:
                        pixel = im.getpixel((319,y))
                #r = 0; g = 1; b = 2'''s
                bw=pixel[0] * 299/1000 + pixel[1] * 587/1000 + pixel[2] * 114/1000
                bw_sum=bw_sum+bw
                if (y%2 == 0):
                    bw_average = bw_sum/4/(256/16) #average + 16 levels of Atari mode
                else:
                    bw_average = bw_sum/4/(256/8)
            line.append( bw_average)
        screen.append(line)
    #screen contains the data pixel by pixel 
    #screen40 has got pixels merged into bytes
        
    screen40=[]
    for line in screen:
        line40=[]
        for i in range (0,40):
            longpix=0
            for j in range (0,2):
                if j==0:
                    longpix=longpix+16*line[i*2+j]
                else:
                    longpix=longpix+line[i*2+j]
            line40.append(longpix)
        screen40.append(line40)
    return screen40

def getLines(screen,lineFrom=0,lineTo=0):
    ''' from .. to using python convention, that is 0..1 means just 0
    '''
    if lineTo == 0:
        lineTo = len(screen)/8
    charScreenLines=[]
    for y in range(lineFrom,lineTo):
        for x in range (0, len(screen[0])):
            charScreenLines.append(getCharacter(screen,x,y))
    return charScreenLines


def getCharacter (screen, x, y):
    ''' returns 8 bytes - each from one line
    x - [0,39]
    y - [0,(height/8)-1], because only y%8==0 makes sense!
    '''
    character = []
    for iy in range(0,8):
        character.append(screen[y*8+iy][x])
    return character

def vecDist(a,b):
    def ab_q(a,b):
        c=(a-b)
        return c*c
    
    dist=0.0
    for i in range (0,8):
        dist = dist + ab_q(a[i]&0xF,b[i]&0xF)
    for i in range (0,8):
        dist = dist + ab_q(a[i]>>4,b[i]>>4)
    return sqrt(dist)

def vecDist1bit(a,b):
    def ab_q(a,b):
        c=(a-b)
        return c*c
    
    dist=0.0
    
    for byte in range (0,8):
        for bit in range (0,8):
            dist = dist + ab_q(a[byte]&(1<<bit),b[byte]&(1<<bit))
    '''
    for byte in range (0,8):
        dist = dist + ab_q(a[byte],b[byte])
    '''    
    return sqrt(dist)

def getDistances(charScreen):
    distTriangle = []
    for i in range(0,len(charScreen)):
        distTriangleLine = []
        for j in range(0,i-1):
            distTriangleLine.append(vecDist(charScreen[i],charScreen[j]))
        distTriangle.append(distTriangleLine)
    return distTriangle

def remCand(charScreen,distTriangle,mino,maxo,start=1):
    ''' finds first pair of chars with distance between mino and maxo
        can _start_ not from the beginning - it is used in the optimisation
    '''
    for i in range(start,len(charScreen)):
        for j in range(0,i-1):
            if mino <= distTriangle[i][j] < maxo:
                return [i,j]    

def optimiseCharScreen(charScreen,finalSize=128,delta=0.1):
    distTriangle = getDistances(charScreen)
    tableLenght = len(charScreen)

    mino = 0.0
    maxo = mino + delta

    mapTable = range(0, tableLenght)
    start = 1
    while len(charScreen) > finalSize:

        candidates = remCand(charScreen,distTriangle,mino,maxo,start)
        if not candidates:
            mino = mino + delta
            maxo = maxo + delta
            #print(maxo)
            start = 1
            continue
        start = candidates[0]
        #print "candidates:",candidates

        destin = max(candidates) # this char will be removed
        source = min(candidates) # and replaced by this one

        charScreen[destin:] = charScreen[destin+1:]
        
        for j in range(0, tableLenght):
            if mapTable[j]== destin:
                mapTable[j] = source
            if mapTable[j] > destin:
                mapTable[j] = mapTable[j]-1
        
        #removing line #destin from distTriangle
        distTriangle.pop(destin)
        #removiig column #destin
        for i in range (destin+1,len(distTriangle)):
            distTriangle[i].pop(destin)

    return mapTable
