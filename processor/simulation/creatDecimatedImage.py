from operator import index
import cv2 as cv
import numpy as np

imageFile = open('decimatedImage.txt', 'r')

memBytes = imageFile.readlines()

imageHeight = int(memBytes[0].split(' ')[1]) + int(memBytes[1].split(' ')[1])*256
imageWidth = int(memBytes[2].split(' ')[1]) + int(memBytes[3].split(' ')[1])*256

img = np.zeros((imageHeight, imageWidth), np.uint8)
index = 4

#print(imageHeight, imageWidth)

for rowNo in range(imageHeight):
    for colNo in range(imageWidth):
        img[rowNo][colNo] = int(memBytes[index].split(' ')[1])
        #print(index)
        index += 1

cv.imwrite('decimatedImage.jpg', img)

cv.imshow('decimatedImage', img)
cv.waitKey()
cv.destroyAllWindows